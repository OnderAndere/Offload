// Offload's handwriting reader (T6a.2, DD-021): reads the text in one image
// with a vision model through llama.cpp and mtmd, on the CPU. The image
// comes in as pixels in memory; nothing is written to disk (CLAUDE.md
// rule 2). Called through dart:ffi from a background isolate.
#ifndef OFFLOAD_LLAMA_H
#define OFFLOAD_LLAMA_H

#include <stdint.h>

#ifdef _WIN32
#  ifdef OFFLOAD_LLAMA_BUILD
#    define OL_API __declspec(dllexport)
#  else
#    define OL_API __declspec(dllimport)
#  endif
#else
#  define OL_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// What ol_read is doing, in ol_status.phase.
enum ol_phase {
  OL_PHASE_IDLE = 0,
  OL_PHASE_LOADING = 1,   // reading the model files into memory
  OL_PHASE_ENCODING = 2,  // the model looks at the image (most of the time)
  OL_PHASE_WRITING = 3,   // the model writes the text
  OL_PHASE_DONE = 4,
};

// Why ol_read gave no text, in ol_result.error.
enum ol_error {
  OL_OK = 0,
  OL_ERROR_MODEL = 1,      // the language model could not be loaded
  OL_ERROR_PROJECTOR = 2,  // the image projector (mmproj) could not be loaded
  OL_ERROR_CONTEXT = 3,    // no context (too little memory)
  OL_ERROR_IMAGE = 4,      // the pixels are not a usable image
  OL_ERROR_TOKENIZE = 5,
  OL_ERROR_EVAL = 6,       // encoding or decoding failed
  OL_ERROR_CANCELLED = 7,  // ol_status.cancel was set
};

// Shared with the caller while ol_read runs: the caller may set cancel to
// a non-zero value at any time and may read phase and tokens to show
// progress. Each field is written whole; allocate with ol_alloc.
typedef struct {
  volatile int32_t cancel;
  volatile int32_t phase;   // enum ol_phase
  volatile int32_t tokens;  // text tokens written so far
} ol_status;

// The outcome of ol_read; text is UTF-8 (free it with ol_free), or NULL
// when error is set. Times in milliseconds.
typedef struct {
  char *text;
  int32_t error;  // enum ol_error
  double load_ms;
  double encode_ms;
  double total_ms;
} ol_result;

// Reads the handwriting in an image of width x height pixels, 3 bytes
// (R, G, B) per pixel, row by row. model_path and mmproj_path are UTF-8.
// image_max_tokens 0 keeps the model's own number of image tokens; a
// lower value reads faster and less accurately. Loads the model, reads
// and frees everything again; blocks until done. One call at a time.
OL_API void ol_read(const char *model_path, const char *mmproj_path,
                    const uint8_t *rgb, int32_t width, int32_t height,
                    const char *prompt, int32_t threads, int32_t n_ctx,
                    int32_t image_max_tokens, int32_t max_tokens,
                    ol_status *status, ol_result *result);

// Memory for the arguments and results above, so the caller needs no
// allocator of its own; ol_alloc returns zeroed memory.
OL_API void *ol_alloc(int64_t size);
OL_API void ol_free(void *p);

#ifdef __cplusplus
}
#endif

#endif  // OFFLOAD_LLAMA_H
