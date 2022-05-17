# TODO

I think when we throw that session exception (even though that is the wrong) place,
by throwing we may throw it when the next queue we'd iterate to was filled and we looped
pver something flushed, but throw because invalid (now) queue operation

We should think about this and maybe chekc rather using a public, isAlice, and if so wthen finish up to try read as
much as possible from the queues even when socket is dead but THEN never loop again (kill the Tasky loop).

It is always passing, but I should consider the above as it is a possible case.

But I do have something hanging, I need to check what that is, I believe wait that may be tristanable threads etc, I don't think newSys is erroring correctly

It might with or without newSys be hanging, socket error shit fr do be annoying me, idk needs more testing.

wait no shit looks fine lmao, we are reaching `"Err"` which is good