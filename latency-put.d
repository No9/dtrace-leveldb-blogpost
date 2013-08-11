#!/usr/sbin/dtrace -s

pid$1::_ZN9leveldown8Database3PutERKN2v89ArgumentsE:entry
{
  self->ts = timestamp;
}

pid$1::_ZN9leveldown8Database3PutERKN2v89ArgumentsE:return
/self->ts/
{
  @[probefunc] = quantize(timestamp - self->ts); 
}

END
{
  printa("SYSCALL NSECS                        # OF OCCURANCES\n%s%@1x\n", @);
}

