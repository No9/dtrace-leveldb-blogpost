#!/usr/sbin/dtrace -Cs

typedef struct Argument
{
  char *data_; 
  size_t  size_;
}Argument_a;
pid$1::_ZN7leveldb10WriteBatch3PutERKNS_5SliceES3_:entry
{
  this->key_ptr = arg1;
  this->key_ptr_arg=(Argument_a*)copyin(this->key_ptr, sizeof(Argument_a));
  
  printf("\n Key:  %s", stringof(copyin((uintptr_t)((Argument_a*)this->key_ptr_arg)->data_, (uintptr_t)((Argument_a*)this->key_ptr_arg)->size_)));

  this->val_ptr = arg2;
  this->val_ptr_arg=(Argument_a*)copyin(this->val_ptr, sizeof(Argument_a));
 
  printf("\n Value:%s", stringof(copyin((uintptr_t)((Argument_a*)this->val_ptr_arg)->data_, (uintptr_t)((Argument_a*)this->val_ptr_arg)->size_)));
}
