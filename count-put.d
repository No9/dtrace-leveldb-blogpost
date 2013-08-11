#!/usr/sbin/dtrace -s

/*
pid$1::_ZN9leveldown8Database3PutERKN2v89ArgumentsE:entry
pid$1::_ZN7leveldb10WriteBatch3PutERKNS_5SliceES3_:entry
pid$1::_ZN9leveldown8Database13PutToDatabaseEPN7leveldb12WriteOptionsENS1_5SliceES4_:entry
*/
pid$1::_ZN9leveldown8Database3PutERKN2v89ArgumentsE:entry
{
  @n[probefunc] = count();
}
END
{
  printa(@n);
}

