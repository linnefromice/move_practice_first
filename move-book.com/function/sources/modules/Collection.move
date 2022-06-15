module 0x9::Collection {
  use std::vector;
  use std::signer;

  struct Item has store, drop{
    // we'll think of the properties later
  }

  struct Collection has key, store {
    items: vector<Item>
  }
  
  /// note that &signer type is passed here!
  public fun start_collection(account: &signer) {
    move_to<Collection>(account, Collection {
      items: vector::empty<Item>()
    })
  }

  /// this function will check if resource exists at address
  public fun exists_at(at: address): bool {
    exists<Collection>(at)
  }

  /// get collection size
  /// mind keyword acquires
  public fun size(account: &signer): u64 acquires Collection {
    let owner = signer::address_of(account);
    let collection = borrow_global<Collection>(owner);

    vector::length(&collection.items)
  }

  public fun add_item(account: &signer) acquires Collection {
    let collection = borrow_global_mut<Collection>(signer::address_of(account));
    vector::push_back(&mut collection.items, Item { });
  }

  public destroy(account: &signer) acquires Collection {
    // account no longer has resource attached
    let collection = move_from<Collection>(Signer::address_of(account));
    
    // now we must use resource value - we'll destructure it
    // look carefully - Items must have drop ability
    let Collection { items: _ } = collection;

    // done. resouirce destroyed
  }
}
