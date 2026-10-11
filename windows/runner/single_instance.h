#ifndef RUNNER_SINGLE_INSTANCE_H_
#define RUNNER_SINGLE_INSTANCE_H_

// Guarantees one Offload process per user session (DD-003): two processes
// would share one device id with separate hybrid logical clocks and could
// hand out duplicate or non-increasing HLCs.
class SingleInstance {
 public:
  enum class Result {
    // This process is the only instance and may start.
    kAcquired,
    // Another instance is running; its window was brought to the front
    // when it already existed.
    kAlreadyRunning,
    // The guard could not be created; starting would be unsafe.
    kFailed,
  };

  SingleInstance() = default;
  ~SingleInstance();

  SingleInstance(const SingleInstance&) = delete;
  SingleInstance& operator=(const SingleInstance&) = delete;

  // Claims the per-session guard. Keep this object alive for the lifetime of
  // the process; the guard is released when it is destroyed.
  Result Acquire();

 private:
  void* mutex_ = nullptr;
};

#endif  // RUNNER_SINGLE_INSTANCE_H_
