#ifndef RUNNER_URL_DISPATCHER_H_
#define RUNNER_URL_DISPATCHER_H_

#include <flutter_linux/flutter_linux.h>

// Canal cotacao_direta/url_dispatcher: repassa URLs ao URL dispatcher do
// Lomiri, no Ubuntu Touch (ver lib/util/ubuntu_touch_url_launcher.dart).
void url_dispatcher_register(FlView* view);

#endif  // RUNNER_URL_DISPATCHER_H_
