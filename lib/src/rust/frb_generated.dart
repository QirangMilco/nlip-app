// This file is automatically generated, so please do not edit it.
// @generated by `flutter_rust_bridge`@ 2.8.0.

// ignore_for_file: unused_import, unused_element, unnecessary_import, duplicate_ignore, invalid_use_of_internal_member, annotate_overrides, non_constant_identifier_names, curly_braces_in_flow_control_structures, prefer_const_literals_to_create_immutables, unused_field

import 'api/nlip_api.dart';
import 'dart:async';
import 'dart:convert';
import 'frb_generated.dart';
import 'frb_generated.io.dart'
    if (dart.library.js_interop) 'frb_generated.web.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

/// Main entrypoint of the Rust API
class RustLib extends BaseEntrypoint<RustLibApi, RustLibApiImpl, RustLibWire> {
  @internal
  static final instance = RustLib._();

  RustLib._();

  /// Initialize flutter_rust_bridge
  static Future<void> init({
    RustLibApi? api,
    BaseHandler? handler,
    ExternalLibrary? externalLibrary,
  }) async {
    await instance.initImpl(
      api: api,
      handler: handler,
      externalLibrary: externalLibrary,
    );
  }

  /// Initialize flutter_rust_bridge in mock mode.
  /// No libraries for FFI are loaded.
  static void initMock({required RustLibApi api}) {
    instance.initMockImpl(api: api);
  }

  /// Dispose flutter_rust_bridge
  ///
  /// The call to this function is optional, since flutter_rust_bridge (and everything else)
  /// is automatically disposed when the app stops.
  static void dispose() => instance.disposeImpl();

  @override
  ApiImplConstructor<RustLibApiImpl, RustLibWire> get apiImplConstructor =>
      RustLibApiImpl.new;

  @override
  WireConstructor<RustLibWire> get wireConstructor =>
      RustLibWire.fromExternalLibrary;

  @override
  Future<void> executeRustInitializers() async {
    await api.crateApiNlipApiInitApp();
  }

  @override
  ExternalLibraryLoaderConfig get defaultExternalLibraryLoaderConfig =>
      kDefaultExternalLibraryLoaderConfig;

  @override
  String get codegenVersion => '2.8.0';

  @override
  int get rustContentHash => 737554361;

  static const kDefaultExternalLibraryLoaderConfig =
      ExternalLibraryLoaderConfig(
        stem: 'rust_lib_nlip_app',
        ioDirectory: 'rust/target/release/',
        webPrefix: 'pkg/',
      );
}

abstract class RustLibApi extends BaseApi {
  Future<CreateSpaceResponse> crateApiNlipApiCreateSpace({
    required String serverUrl,
    required String token,
    required String name,
  });

  Future<ClipResponse> crateApiNlipApiGetLastClip({
    required String serverUrl,
    required String token,
    required String spaceId,
  });

  Future<SpacesListResponse> crateApiNlipApiGetSpacesList({
    required String serverUrl,
    required String token,
  });

  String crateApiNlipApiGreet({required String name});

  Future<void> crateApiNlipApiInitApp();

  Future<LoginResponse> crateApiNlipApiLogin({
    required String serverUrl,
    required String username,
    required String token,
  });

  Future<ClipResponse> crateApiNlipApiUploadTextClip({
    required String serverUrl,
    required String token,
    required String spaceId,
    required String content,
  });
}

class RustLibApiImpl extends RustLibApiImplPlatform implements RustLibApi {
  RustLibApiImpl({
    required super.handler,
    required super.wire,
    required super.generalizedFrbRustBinding,
    required super.portManager,
  });

  @override
  Future<CreateSpaceResponse> crateApiNlipApiCreateSpace({
    required String serverUrl,
    required String token,
    required String name,
  }) {
    return handler.executeNormal(
      NormalTask(
        callFfi: (port_) {
          final serializer = SseSerializer(generalizedFrbRustBinding);
          sse_encode_String(serverUrl, serializer);
          sse_encode_String(token, serializer);
          sse_encode_String(name, serializer);
          pdeCallFfi(
            generalizedFrbRustBinding,
            serializer,
            funcId: 1,
            port: port_,
          );
        },
        codec: SseCodec(
          decodeSuccessData: sse_decode_create_space_response,
          decodeErrorData: sse_decode_api_error,
        ),
        constMeta: kCrateApiNlipApiCreateSpaceConstMeta,
        argValues: [serverUrl, token, name],
        apiImpl: this,
      ),
    );
  }

  TaskConstMeta get kCrateApiNlipApiCreateSpaceConstMeta => const TaskConstMeta(
    debugName: "create_space",
    argNames: ["serverUrl", "token", "name"],
  );

  @override
  Future<ClipResponse> crateApiNlipApiGetLastClip({
    required String serverUrl,
    required String token,
    required String spaceId,
  }) {
    return handler.executeNormal(
      NormalTask(
        callFfi: (port_) {
          final serializer = SseSerializer(generalizedFrbRustBinding);
          sse_encode_String(serverUrl, serializer);
          sse_encode_String(token, serializer);
          sse_encode_String(spaceId, serializer);
          pdeCallFfi(
            generalizedFrbRustBinding,
            serializer,
            funcId: 2,
            port: port_,
          );
        },
        codec: SseCodec(
          decodeSuccessData: sse_decode_clip_response,
          decodeErrorData: sse_decode_api_error,
        ),
        constMeta: kCrateApiNlipApiGetLastClipConstMeta,
        argValues: [serverUrl, token, spaceId],
        apiImpl: this,
      ),
    );
  }

  TaskConstMeta get kCrateApiNlipApiGetLastClipConstMeta => const TaskConstMeta(
    debugName: "get_last_clip",
    argNames: ["serverUrl", "token", "spaceId"],
  );

  @override
  Future<SpacesListResponse> crateApiNlipApiGetSpacesList({
    required String serverUrl,
    required String token,
  }) {
    return handler.executeNormal(
      NormalTask(
        callFfi: (port_) {
          final serializer = SseSerializer(generalizedFrbRustBinding);
          sse_encode_String(serverUrl, serializer);
          sse_encode_String(token, serializer);
          pdeCallFfi(
            generalizedFrbRustBinding,
            serializer,
            funcId: 3,
            port: port_,
          );
        },
        codec: SseCodec(
          decodeSuccessData: sse_decode_spaces_list_response,
          decodeErrorData: sse_decode_api_error,
        ),
        constMeta: kCrateApiNlipApiGetSpacesListConstMeta,
        argValues: [serverUrl, token],
        apiImpl: this,
      ),
    );
  }

  TaskConstMeta get kCrateApiNlipApiGetSpacesListConstMeta =>
      const TaskConstMeta(
        debugName: "get_spaces_list",
        argNames: ["serverUrl", "token"],
      );

  @override
  String crateApiNlipApiGreet({required String name}) {
    return handler.executeSync(
      SyncTask(
        callFfi: () {
          final serializer = SseSerializer(generalizedFrbRustBinding);
          sse_encode_String(name, serializer);
          return pdeCallFfi(generalizedFrbRustBinding, serializer, funcId: 4)!;
        },
        codec: SseCodec(
          decodeSuccessData: sse_decode_String,
          decodeErrorData: null,
        ),
        constMeta: kCrateApiNlipApiGreetConstMeta,
        argValues: [name],
        apiImpl: this,
      ),
    );
  }

  TaskConstMeta get kCrateApiNlipApiGreetConstMeta =>
      const TaskConstMeta(debugName: "greet", argNames: ["name"]);

  @override
  Future<void> crateApiNlipApiInitApp() {
    return handler.executeNormal(
      NormalTask(
        callFfi: (port_) {
          final serializer = SseSerializer(generalizedFrbRustBinding);
          pdeCallFfi(
            generalizedFrbRustBinding,
            serializer,
            funcId: 5,
            port: port_,
          );
        },
        codec: SseCodec(
          decodeSuccessData: sse_decode_unit,
          decodeErrorData: null,
        ),
        constMeta: kCrateApiNlipApiInitAppConstMeta,
        argValues: [],
        apiImpl: this,
      ),
    );
  }

  TaskConstMeta get kCrateApiNlipApiInitAppConstMeta =>
      const TaskConstMeta(debugName: "init_app", argNames: []);

  @override
  Future<LoginResponse> crateApiNlipApiLogin({
    required String serverUrl,
    required String username,
    required String token,
  }) {
    return handler.executeNormal(
      NormalTask(
        callFfi: (port_) {
          final serializer = SseSerializer(generalizedFrbRustBinding);
          sse_encode_String(serverUrl, serializer);
          sse_encode_String(username, serializer);
          sse_encode_String(token, serializer);
          pdeCallFfi(
            generalizedFrbRustBinding,
            serializer,
            funcId: 6,
            port: port_,
          );
        },
        codec: SseCodec(
          decodeSuccessData: sse_decode_login_response,
          decodeErrorData: sse_decode_api_error,
        ),
        constMeta: kCrateApiNlipApiLoginConstMeta,
        argValues: [serverUrl, username, token],
        apiImpl: this,
      ),
    );
  }

  TaskConstMeta get kCrateApiNlipApiLoginConstMeta => const TaskConstMeta(
    debugName: "login",
    argNames: ["serverUrl", "username", "token"],
  );

  @override
  Future<ClipResponse> crateApiNlipApiUploadTextClip({
    required String serverUrl,
    required String token,
    required String spaceId,
    required String content,
  }) {
    return handler.executeNormal(
      NormalTask(
        callFfi: (port_) {
          final serializer = SseSerializer(generalizedFrbRustBinding);
          sse_encode_String(serverUrl, serializer);
          sse_encode_String(token, serializer);
          sse_encode_String(spaceId, serializer);
          sse_encode_String(content, serializer);
          pdeCallFfi(
            generalizedFrbRustBinding,
            serializer,
            funcId: 7,
            port: port_,
          );
        },
        codec: SseCodec(
          decodeSuccessData: sse_decode_clip_response,
          decodeErrorData: sse_decode_api_error,
        ),
        constMeta: kCrateApiNlipApiUploadTextClipConstMeta,
        argValues: [serverUrl, token, spaceId, content],
        apiImpl: this,
      ),
    );
  }

  TaskConstMeta get kCrateApiNlipApiUploadTextClipConstMeta =>
      const TaskConstMeta(
        debugName: "upload_text_clip",
        argNames: ["serverUrl", "token", "spaceId", "content"],
      );

  @protected
  String dco_decode_String(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return raw as String;
  }

  @protected
  ApiError dco_decode_api_error(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    switch (raw[0]) {
      case 0:
        return ApiError_NetworkError(dco_decode_String(raw[1]));
      case 1:
        return ApiError_ServerError(
          code: dco_decode_i_32(raw[1]),
          message: dco_decode_String(raw[2]),
        );
      case 2:
        return ApiError_DeserializeError(dco_decode_String(raw[1]));
      case 3:
        return ApiError_Other(dco_decode_String(raw[1]));
      default:
        throw Exception("unreachable");
    }
  }

  @protected
  bool dco_decode_bool(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return raw as bool;
  }

  @protected
  Clip dco_decode_clip(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    final arr = raw as List<dynamic>;
    if (arr.length != 9)
      throw Exception('unexpected arr length: expect 9 but see ${arr.length}');
    return Clip(
      id: dco_decode_String(arr[0]),
      clipId: dco_decode_String(arr[1]),
      spaceId: dco_decode_String(arr[2]),
      content: dco_decode_String(arr[3]),
      contentType: dco_decode_String(arr[4]),
      creator: dco_decode_clip_creator(arr[5]),
      createdAt: dco_decode_String(arr[6]),
      updatedAt: dco_decode_String(arr[7]),
      filePath: dco_decode_String(arr[8]),
    );
  }

  @protected
  ClipCreator dco_decode_clip_creator(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    final arr = raw as List<dynamic>;
    if (arr.length != 2)
      throw Exception('unexpected arr length: expect 2 but see ${arr.length}');
    return ClipCreator(
      id: dco_decode_String(arr[0]),
      username: dco_decode_String(arr[1]),
    );
  }

  @protected
  ClipResponse dco_decode_clip_response(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    final arr = raw as List<dynamic>;
    if (arr.length != 1)
      throw Exception('unexpected arr length: expect 1 but see ${arr.length}');
    return ClipResponse(clip: dco_decode_clip(arr[0]));
  }

  @protected
  CreateSpaceResponse dco_decode_create_space_response(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    final arr = raw as List<dynamic>;
    if (arr.length != 1)
      throw Exception('unexpected arr length: expect 1 but see ${arr.length}');
    return CreateSpaceResponse(space: dco_decode_space(arr[0]));
  }

  @protected
  int dco_decode_i_32(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return raw as int;
  }

  @protected
  Uint8List dco_decode_list_prim_u_8_strict(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return raw as Uint8List;
  }

  @protected
  List<Space> dco_decode_list_space(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return (raw as List<dynamic>).map(dco_decode_space).toList();
  }

  @protected
  LoginResponse dco_decode_login_response(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    final arr = raw as List<dynamic>;
    if (arr.length != 2)
      throw Exception('unexpected arr length: expect 2 but see ${arr.length}');
    return LoginResponse(
      jwtToken: dco_decode_String(arr[0]),
      user: dco_decode_user(arr[1]),
    );
  }

  @protected
  Space dco_decode_space(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    final arr = raw as List<dynamic>;
    if (arr.length != 8)
      throw Exception('unexpected arr length: expect 8 but see ${arr.length}');
    return Space(
      id: dco_decode_String(arr[0]),
      name: dco_decode_String(arr[1]),
      typeField: dco_decode_String(arr[2]),
      ownerId: dco_decode_String(arr[3]),
      maxItems: dco_decode_i_32(arr[4]),
      retentionDays: dco_decode_i_32(arr[5]),
      createdAt: dco_decode_String(arr[6]),
      updatedAt: dco_decode_String(arr[7]),
    );
  }

  @protected
  SpacesListResponse dco_decode_spaces_list_response(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    final arr = raw as List<dynamic>;
    if (arr.length != 1)
      throw Exception('unexpected arr length: expect 1 but see ${arr.length}');
    return SpacesListResponse(spaces: dco_decode_list_space(arr[0]));
  }

  @protected
  int dco_decode_u_8(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return raw as int;
  }

  @protected
  void dco_decode_unit(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return;
  }

  @protected
  User dco_decode_user(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    final arr = raw as List<dynamic>;
    if (arr.length != 5)
      throw Exception('unexpected arr length: expect 5 but see ${arr.length}');
    return User(
      id: dco_decode_String(arr[0]),
      username: dco_decode_String(arr[1]),
      isAdmin: dco_decode_bool(arr[2]),
      needChangePwd: dco_decode_bool(arr[3]),
      createdAt: dco_decode_String(arr[4]),
    );
  }

  @protected
  String sse_decode_String(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var inner = sse_decode_list_prim_u_8_strict(deserializer);
    return utf8.decoder.convert(inner);
  }

  @protected
  ApiError sse_decode_api_error(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs

    var tag_ = sse_decode_i_32(deserializer);
    switch (tag_) {
      case 0:
        var var_field0 = sse_decode_String(deserializer);
        return ApiError_NetworkError(var_field0);
      case 1:
        var var_code = sse_decode_i_32(deserializer);
        var var_message = sse_decode_String(deserializer);
        return ApiError_ServerError(code: var_code, message: var_message);
      case 2:
        var var_field0 = sse_decode_String(deserializer);
        return ApiError_DeserializeError(var_field0);
      case 3:
        var var_field0 = sse_decode_String(deserializer);
        return ApiError_Other(var_field0);
      default:
        throw UnimplementedError('');
    }
  }

  @protected
  bool sse_decode_bool(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return deserializer.buffer.getUint8() != 0;
  }

  @protected
  Clip sse_decode_clip(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var var_id = sse_decode_String(deserializer);
    var var_clipId = sse_decode_String(deserializer);
    var var_spaceId = sse_decode_String(deserializer);
    var var_content = sse_decode_String(deserializer);
    var var_contentType = sse_decode_String(deserializer);
    var var_creator = sse_decode_clip_creator(deserializer);
    var var_createdAt = sse_decode_String(deserializer);
    var var_updatedAt = sse_decode_String(deserializer);
    var var_filePath = sse_decode_String(deserializer);
    return Clip(
      id: var_id,
      clipId: var_clipId,
      spaceId: var_spaceId,
      content: var_content,
      contentType: var_contentType,
      creator: var_creator,
      createdAt: var_createdAt,
      updatedAt: var_updatedAt,
      filePath: var_filePath,
    );
  }

  @protected
  ClipCreator sse_decode_clip_creator(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var var_id = sse_decode_String(deserializer);
    var var_username = sse_decode_String(deserializer);
    return ClipCreator(id: var_id, username: var_username);
  }

  @protected
  ClipResponse sse_decode_clip_response(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var var_clip = sse_decode_clip(deserializer);
    return ClipResponse(clip: var_clip);
  }

  @protected
  CreateSpaceResponse sse_decode_create_space_response(
    SseDeserializer deserializer,
  ) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var var_space = sse_decode_space(deserializer);
    return CreateSpaceResponse(space: var_space);
  }

  @protected
  int sse_decode_i_32(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return deserializer.buffer.getInt32();
  }

  @protected
  Uint8List sse_decode_list_prim_u_8_strict(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var len_ = sse_decode_i_32(deserializer);
    return deserializer.buffer.getUint8List(len_);
  }

  @protected
  List<Space> sse_decode_list_space(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs

    var len_ = sse_decode_i_32(deserializer);
    var ans_ = <Space>[];
    for (var idx_ = 0; idx_ < len_; ++idx_) {
      ans_.add(sse_decode_space(deserializer));
    }
    return ans_;
  }

  @protected
  LoginResponse sse_decode_login_response(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var var_jwtToken = sse_decode_String(deserializer);
    var var_user = sse_decode_user(deserializer);
    return LoginResponse(jwtToken: var_jwtToken, user: var_user);
  }

  @protected
  Space sse_decode_space(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var var_id = sse_decode_String(deserializer);
    var var_name = sse_decode_String(deserializer);
    var var_typeField = sse_decode_String(deserializer);
    var var_ownerId = sse_decode_String(deserializer);
    var var_maxItems = sse_decode_i_32(deserializer);
    var var_retentionDays = sse_decode_i_32(deserializer);
    var var_createdAt = sse_decode_String(deserializer);
    var var_updatedAt = sse_decode_String(deserializer);
    return Space(
      id: var_id,
      name: var_name,
      typeField: var_typeField,
      ownerId: var_ownerId,
      maxItems: var_maxItems,
      retentionDays: var_retentionDays,
      createdAt: var_createdAt,
      updatedAt: var_updatedAt,
    );
  }

  @protected
  SpacesListResponse sse_decode_spaces_list_response(
    SseDeserializer deserializer,
  ) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var var_spaces = sse_decode_list_space(deserializer);
    return SpacesListResponse(spaces: var_spaces);
  }

  @protected
  int sse_decode_u_8(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return deserializer.buffer.getUint8();
  }

  @protected
  void sse_decode_unit(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
  }

  @protected
  User sse_decode_user(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var var_id = sse_decode_String(deserializer);
    var var_username = sse_decode_String(deserializer);
    var var_isAdmin = sse_decode_bool(deserializer);
    var var_needChangePwd = sse_decode_bool(deserializer);
    var var_createdAt = sse_decode_String(deserializer);
    return User(
      id: var_id,
      username: var_username,
      isAdmin: var_isAdmin,
      needChangePwd: var_needChangePwd,
      createdAt: var_createdAt,
    );
  }

  @protected
  void sse_encode_String(String self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_list_prim_u_8_strict(utf8.encoder.convert(self), serializer);
  }

  @protected
  void sse_encode_api_error(ApiError self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    switch (self) {
      case ApiError_NetworkError(field0: final field0):
        sse_encode_i_32(0, serializer);
        sse_encode_String(field0, serializer);
      case ApiError_ServerError(code: final code, message: final message):
        sse_encode_i_32(1, serializer);
        sse_encode_i_32(code, serializer);
        sse_encode_String(message, serializer);
      case ApiError_DeserializeError(field0: final field0):
        sse_encode_i_32(2, serializer);
        sse_encode_String(field0, serializer);
      case ApiError_Other(field0: final field0):
        sse_encode_i_32(3, serializer);
        sse_encode_String(field0, serializer);
    }
  }

  @protected
  void sse_encode_bool(bool self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    serializer.buffer.putUint8(self ? 1 : 0);
  }

  @protected
  void sse_encode_clip(Clip self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_String(self.id, serializer);
    sse_encode_String(self.clipId, serializer);
    sse_encode_String(self.spaceId, serializer);
    sse_encode_String(self.content, serializer);
    sse_encode_String(self.contentType, serializer);
    sse_encode_clip_creator(self.creator, serializer);
    sse_encode_String(self.createdAt, serializer);
    sse_encode_String(self.updatedAt, serializer);
    sse_encode_String(self.filePath, serializer);
  }

  @protected
  void sse_encode_clip_creator(ClipCreator self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_String(self.id, serializer);
    sse_encode_String(self.username, serializer);
  }

  @protected
  void sse_encode_clip_response(ClipResponse self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_clip(self.clip, serializer);
  }

  @protected
  void sse_encode_create_space_response(
    CreateSpaceResponse self,
    SseSerializer serializer,
  ) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_space(self.space, serializer);
  }

  @protected
  void sse_encode_i_32(int self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    serializer.buffer.putInt32(self);
  }

  @protected
  void sse_encode_list_prim_u_8_strict(
    Uint8List self,
    SseSerializer serializer,
  ) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_i_32(self.length, serializer);
    serializer.buffer.putUint8List(self);
  }

  @protected
  void sse_encode_list_space(List<Space> self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_i_32(self.length, serializer);
    for (final item in self) {
      sse_encode_space(item, serializer);
    }
  }

  @protected
  void sse_encode_login_response(LoginResponse self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_String(self.jwtToken, serializer);
    sse_encode_user(self.user, serializer);
  }

  @protected
  void sse_encode_space(Space self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_String(self.id, serializer);
    sse_encode_String(self.name, serializer);
    sse_encode_String(self.typeField, serializer);
    sse_encode_String(self.ownerId, serializer);
    sse_encode_i_32(self.maxItems, serializer);
    sse_encode_i_32(self.retentionDays, serializer);
    sse_encode_String(self.createdAt, serializer);
    sse_encode_String(self.updatedAt, serializer);
  }

  @protected
  void sse_encode_spaces_list_response(
    SpacesListResponse self,
    SseSerializer serializer,
  ) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_list_space(self.spaces, serializer);
  }

  @protected
  void sse_encode_u_8(int self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    serializer.buffer.putUint8(self);
  }

  @protected
  void sse_encode_unit(void self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
  }

  @protected
  void sse_encode_user(User self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_String(self.id, serializer);
    sse_encode_String(self.username, serializer);
    sse_encode_bool(self.isAdmin, serializer);
    sse_encode_bool(self.needChangePwd, serializer);
    sse_encode_String(self.createdAt, serializer);
  }
}
