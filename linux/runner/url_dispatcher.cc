#include "url_dispatcher.h"

#include <gio/gio.h>

#include <cstring>

// Interface do lomiri-url-dispatcher. O perfil padrão do AppArmor dos apps
// click libera exatamente esta chamada (DispatchURL), sem grupo de política
// extra.
static constexpr char kBusName[] = "com.lomiri.URLDispatcher";
static constexpr char kObjectPath[] = "/com/lomiri/URLDispatcher";
static constexpr char kInterface[] = "com.lomiri.URLDispatcher";

static void respond_bool(FlMethodCall* method_call, gboolean value) {
  g_autoptr(FlValue) result = fl_value_new_bool(value);
  g_autoptr(FlMethodResponse) response =
      FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  fl_method_call_respond(method_call, response, nullptr);
}

static void dispatch_url_cb(GObject* source, GAsyncResult* result,
                            gpointer user_data) {
  g_autoptr(FlMethodCall) method_call = FL_METHOD_CALL(user_data);
  g_autoptr(GError) error = nullptr;
  g_autoptr(GVariant) reply = g_dbus_connection_call_finish(
      G_DBUS_CONNECTION(source), result, &error);
  if (reply == nullptr) {
    g_warning("URL dispatcher recusou a URL: %s", error->message);
  }
  respond_bool(method_call, reply != nullptr);
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  if (strcmp(fl_method_call_get_name(method_call), "dispatch") != 0) {
    g_autoptr(FlMethodResponse) response =
        FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }

  FlValue* args = fl_method_call_get_args(method_call);
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_STRING) {
    g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(
        fl_method_error_response_new("bad-args", "Esperava a URL", nullptr));
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }

  g_autoptr(GError) error = nullptr;
  g_autoptr(GDBusConnection) bus =
      g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &error);
  if (bus == nullptr) {
    g_warning("Sem acesso ao DBus de sessão: %s", error->message);
    respond_bool(method_call, FALSE);
    return;
  }

  // O segundo argumento restringe a URL a um pacote; vazio deixa o
  // dispatcher escolher o app, que é o que se quer para um link da web.
  g_dbus_connection_call(
      bus, kBusName, kObjectPath, kInterface, "DispatchURL",
      g_variant_new("(ss)", fl_value_get_string(args), ""), nullptr,
      G_DBUS_CALL_FLAGS_NONE, -1, nullptr, dispatch_url_cb,
      g_object_ref(method_call));
}

void url_dispatcher_register(FlView* view) {
  FlEngine* engine = fl_view_get_engine(view);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(engine), "cotacao_direta/url_dispatcher",
      FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb, nullptr,
                                            nullptr);
  // O canal vive enquanto a view viver.
  g_object_set_data_full(G_OBJECT(view), "cotacao_direta-url-dispatcher",
                         channel, g_object_unref);
}
