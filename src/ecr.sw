library ecr;

use ::b512::B512;
use ::address::Address;
use ::chain::assert;

/// Recover the public key derived from the private key used to sign a message
pub fn ec_recover(signature: B512, msg_hash: b256) -> B512 {
    let public_key = ~B512::new();

    public_key.hi = asm(buffer, hi: signature.hi, hash: msg_hash) {
        move buffer sp; // Result buffer.
        cfei i32;
        ecr buffer hi hash;
        buffer: b256
    };
    // @note temp
    assert(public_key.hi == 0x1d152307c6b72b0ed0418b0e70cd80e7f5295b8d86f5722d3f5213fbd2394f36);

    // a `B512`'s 2 internal values are stored in contiguous memory. This asm block takes a pointer to the initial value (public_key.hi) and should retrieve the lo value from memory and return it to be stored in public_key.lo.
    public_key.lo = asm(buffer, hi_ptr: public_key.hi, lo_ptr) {
        move buffer sp;
        cfei i32;
        move hi_ptr sp;
        cfei i64;
        addi lo_ptr hi_ptr i32; // set lo_ptr equal to hi_ptr + 32 bytes
        move lo_ptr sp;
        cfei i32;
        mcpi buffer lo_ptr i32; // copy 32 bytes starting at lo_ptr into buffer
        buffer: b256
    };
    // @note temp
    assert(public_key.lo == 0xb7ce9c3e45905178455900b44abb308f3ef480481a4b2ee3f70aca157fde396a);

    public_key
}

/// Recover the address derived from the private key used to sign a message
pub fn ec_recover_address(signature: B512, msg_hash: b256) -> Address {

    // ECR: "The 64-byte public key (x, y) recovered from 64-byte signature starting at $rB on 32-byte message hash starting at $rC"
    // s256: The sha-256 hash of $rC bytes starting at $rB.
    let address = asm(pub_key_buffer, sig_ptr: signature.hi, hash: msg_hash, addr_buffer, sixty_four: 64) {
        move pub_key_buffer sp; // mv sp to pub_key result buffer.
        cfei i64;
        ecr pub_key_buffer sig_ptr hash; // recover public_key from sig & hash
        move addr_buffer sp; // mv sp to addr result buffer.
        cfei i32;
        s256 addr_buffer pub_key_buffer sixty_four; // hash 64 bytes to the addr_buffer
        addr_buffer: b256
    };

    ~Address::from(address)
}
