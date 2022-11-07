module basics::wrapper {
    use sui::object::{Self, UID};
    use sui::tx_context::{TxContext};

    struct Wrapper<T: store> has key, store {
        id: UID,
        contents: T
    }

    public fun contents<T: store>(c: &Wrapper<T>): &T {
        &c.contents
    }

    public fun create<T: store>(contents: T, ctx: &mut TxContext): Wrapper<T> {
        Wrapper {
            id: object::new(ctx),
            contents
        }
    }

    public fun destroy<T: store>(c: Wrapper<T>): T {
        let Wrapper { id, contents } = c;
        object::delete(id);
        contents
    }
}

module basics::profile {
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, String};
    use sui::url::{Self, Url};
    use basics::wrapper;

    struct ProfileInfo has store {
        name: String,
        url: Url
    }

    public fun name(info: &ProfileInfo): &String {
        &info.name
    }

    public fun url(info: &ProfileInfo): &Url {
        &info.url
    }

    /// Creates new `ProfileInfo` and wraps into `Wrapper`
    /// Then transfers to sender
    public fun create_profile(name: vector<u8>, url: vector<u8>, ctx: &mut TxContext) {
        let container = wrapper::create(
            ProfileInfo {
                name: string::utf8(name),
                url: url::new_unsafe_from_bytes(url)
            },
            ctx
        );
        
        // `Wrapper` type is freely transferable
        transfer::transfer(container, tx_context::sender(ctx));
    }
}
