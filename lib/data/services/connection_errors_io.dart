import 'dart:io';

bool isPlatformConnectionFailure(Object error) => error is SocketException;
