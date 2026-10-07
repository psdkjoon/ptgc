part of 'mtp.dart';

// The MTProto layer number this client speaks. Commented out for now
// because it's only needed when implementing layer negotiation via
// `initConnection` — the value is passed directly in the `initConnection`
// call in client.dart instead.
//
// const int _layer = 174;

// The TL constructor ID for the `Vector` type, used when deserializing
// raw vector responses. Kept here as a reference; the generated binary
// reader in tl_g_binary_reader_object.dart handles this directly.
//
// const _vectorCtor = 0x1CB5C415;
