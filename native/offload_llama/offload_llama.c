// See offload_llama.h. Follows llama-mtmd-cli of llama.cpp b11526 for one
// image and one prompt, with greedy sampling (temp 0, DD-021).
#include "offload_llama.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ggml-backend.h"
#include "ggml.h"
#include "llama.h"
#include "mtmd-helper.h"
#include "mtmd.h"

// Graph nodes of the image encoder computed between two looks at
// ol_status.cancel: each look is a short pause of the CPU threads, and
// the encoder of Qwen3-VL has a few thousand nodes.
#define CANCEL_CHECK_NODES 64

static int initialised = 0;

static void quiet(enum ggml_log_level level, const char *text, void *user) {
  (void)level;
  (void)text;
  (void)user;
}

static void init_once(void) {
  if (initialised) return;
  llama_log_set(quiet, NULL);
  mtmd_helper_log_set(quiet, NULL);
  llama_backend_init();
  initialised = 1;
}

static int cancelled(const ol_status *status) { return status->cancel != 0; }

// Model loading: true goes on, false stops.
static bool keep_loading(float progress, void *user) {
  (void)progress;
  return !cancelled((const ol_status *)user);
}

// llama's decoder: true stops.
static bool abort_decoding(void *user) {
  return cancelled((const ol_status *)user);
}

// The image encoder's scheduler asks, per graph node, whether we want to
// see it (ask true); then the nodes up to it are computed and we are called
// again (ask false), where false stops the rest of the graph.
typedef struct {
  ol_status *status;
  int nodes;
} encoder_watch;

static bool watch_encoder(struct ggml_tensor *t, bool ask, void *user) {
  (void)t;
  encoder_watch *w = (encoder_watch *)user;
  if (ask) return ++w->nodes % CANCEL_CHECK_NODES == 0;
  return !cancelled(w->status);
}

static char *chat_prompt(const char *marker, const char *prompt) {
  // The chat format of Qwen3-VL (ChatML), the image before the prompt, as
  // llama-mtmd-cli builds it.
  static const char *head = "<|im_start|>user\n";
  static const char *tail = "<|im_end|>\n<|im_start|>assistant\n";
  size_t n = strlen(head) + strlen(marker) + strlen(prompt) + strlen(tail) + 1;
  char *text = (char *)malloc(n);
  if (!text) return NULL;
  snprintf(text, n, "%s%s%s%s", head, marker, prompt, tail);
  return text;
}

// Appends a piece of text to *out, growing it; false when out of memory.
static int append(char **out, size_t *len, size_t *cap, const char *piece,
                  size_t n) {
  if (*len + n + 1 > *cap) {
    size_t grown = *cap * 2 > *len + n + 1 ? *cap * 2 : *len + n + 1;
    char *bigger = (char *)realloc(*out, grown);
    if (!bigger) return 0;
    *out = bigger;
    *cap = grown;
  }
  memcpy(*out + *len, piece, n);
  *len += n;
  (*out)[*len] = 0;
  return 1;
}

static void finish(ol_result *result, ol_status *status, int32_t error,
                   int64_t t0) {
  if (error != OL_OK && cancelled(status)) error = OL_ERROR_CANCELLED;
  if (error != OL_OK && result->text) {
    free(result->text);
    result->text = NULL;
  }
  result->error = error;
  result->total_ms = (double)(ggml_time_ms() - t0);
  status->phase = OL_PHASE_DONE;
}

void ol_read(const char *model_path, const char *mmproj_path,
             const uint8_t *rgb, int32_t width, int32_t height,
             const char *prompt, int32_t threads, int32_t n_ctx,
             int32_t image_max_tokens, int32_t max_tokens, ol_status *status,
             ol_result *result) {
  init_once();
  const int64_t t0 = ggml_time_ms();
  memset(result, 0, sizeof *result);
  status->phase = OL_PHASE_LOADING;
  status->tokens = 0;

  struct llama_model *model = NULL;
  struct llama_context *lctx = NULL;
  mtmd_context *mctx = NULL;
  mtmd_bitmap *bitmap = NULL;
  mtmd_input_chunks *chunks = NULL;
  struct llama_sampler *sampler = NULL;
  int32_t error = OL_OK;

  // Read into memory, not memory-mapped (DD-021, T6a.1).
  struct llama_model_params mp = llama_model_default_params();
  mp.n_gpu_layers = 0;
  mp.load_mode = LLAMA_LOAD_MODE_NONE;
  mp.progress_callback = keep_loading;
  mp.progress_callback_user_data = status;
  model = llama_model_load_from_file(model_path, mp);
  if (!model) {
    error = OL_ERROR_MODEL;
    goto done;
  }

  struct llama_context_params cp = llama_context_default_params();
  cp.n_ctx = (uint32_t)n_ctx;
  cp.n_batch = (uint32_t)n_ctx;
  cp.n_threads = threads;
  cp.n_threads_batch = threads;
  cp.abort_callback = abort_decoding;
  cp.abort_callback_data = status;
  lctx = llama_init_from_model(model, cp);
  if (!lctx) {
    error = OL_ERROR_CONTEXT;
    goto done;
  }

  encoder_watch watch = {status, 0};
  struct mtmd_context_params mcp = mtmd_context_params_default();
  mcp.use_gpu = false;
  mcp.n_threads = threads;
  mcp.print_timings = false;
  mcp.warmup = false;
  if (image_max_tokens > 0) mcp.image_max_tokens = image_max_tokens;
  mcp.cb_eval = watch_encoder;
  mcp.cb_eval_user_data = &watch;
  mcp.progress_callback = keep_loading;
  mcp.progress_callback_user_data = status;
  mctx = mtmd_init_from_file(mmproj_path, model, mcp);
  if (!mctx) {
    error = OL_ERROR_PROJECTOR;
    goto done;
  }
  result->load_ms = (double)(ggml_time_ms() - t0);
  if (cancelled(status)) {
    error = OL_ERROR_CANCELLED;
    goto done;
  }

  if (!rgb || width <= 0 || height <= 0) {
    error = OL_ERROR_IMAGE;
    goto done;
  }
  bitmap = mtmd_bitmap_init((uint32_t)width, (uint32_t)height, rgb);
  if (!bitmap) {
    error = OL_ERROR_IMAGE;
    goto done;
  }

  char *text = chat_prompt(mtmd_default_marker(), prompt);
  if (!text) {
    error = OL_ERROR_TOKENIZE;
    goto done;
  }
  chunks = mtmd_input_chunks_init();
  if (!chunks) {
    free(text);
    error = OL_ERROR_TOKENIZE;
    goto done;
  }
  mtmd_input_text input = {text, strlen(text), true, true};
  const mtmd_bitmap *bitmaps[1] = {bitmap};
  int32_t rc = mtmd_tokenize(mctx, chunks, &input, bitmaps, 1);
  free(text);
  if (rc != 0) {
    error = OL_ERROR_TOKENIZE;
    goto done;
  }

  status->phase = OL_PHASE_ENCODING;
  const int64_t t1 = ggml_time_ms();
  llama_pos n_past = 0;
  if (mtmd_helper_eval_chunks(mctx, lctx, chunks, 0, 0, n_ctx, true,
                              &n_past) != 0 ||
      cancelled(status)) {
    error = OL_ERROR_EVAL;
    goto done;
  }
  result->encode_ms = (double)(ggml_time_ms() - t1);

  status->phase = OL_PHASE_WRITING;
  const struct llama_vocab *vocab = llama_model_get_vocab(model);
  sampler = llama_sampler_chain_init(llama_sampler_chain_default_params());
  llama_sampler_chain_add(sampler, llama_sampler_init_greedy());
  size_t len = 0, cap = 1024;
  result->text = (char *)malloc(cap);
  if (!result->text) {
    error = OL_ERROR_EVAL;
    goto done;
  }
  result->text[0] = 0;
  // The text ends where the context ends: the image took its part of it.
  const int32_t room = n_ctx - (int32_t)n_past;
  const int32_t limit = max_tokens < room ? max_tokens : room;
  for (int32_t i = 0; i < limit; i++) {
    if (cancelled(status)) {
      error = OL_ERROR_CANCELLED;
      goto done;
    }
    llama_token token = llama_sampler_sample(sampler, lctx, -1);
    if (llama_vocab_is_eog(vocab, token)) break;
    char piece[256];
    int32_t n = llama_token_to_piece(vocab, token, piece, sizeof piece, 0,
                                     false);
    if (n > 0 && !append(&result->text, &len, &cap, piece, (size_t)n)) {
      error = OL_ERROR_EVAL;
      goto done;
    }
    status->tokens = i + 1;
    struct llama_batch batch = llama_batch_get_one(&token, 1);
    if (llama_decode(lctx, batch) != 0) {
      error = OL_ERROR_EVAL;
      goto done;
    }
  }

done:
  if (sampler) llama_sampler_free(sampler);
  if (chunks) mtmd_input_chunks_free(chunks);
  if (bitmap) mtmd_bitmap_free(bitmap);
  if (mctx) mtmd_free(mctx);
  if (lctx) llama_free(lctx);
  if (model) llama_model_free(model);
  finish(result, status, error, t0);
}

void *ol_alloc(int64_t size) {
  if (size <= 0) return NULL;
  return calloc(1, (size_t)size);
}

void ol_free(void *p) { free(p); }
