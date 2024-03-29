module my_first_package::my_module {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct Sword has key, store {
        id: UID,
        magic: u64,
        strength: u64
    }

    struct Forge has key, store {
        id: UID,
        swords_created: u64
    }

    fun init(ctx: &mut TxContext) {
        let admin = Forge {
            id: object::new(ctx),
            swords_created: 0,
        };
        transfer::transfer(admin, tx_context::sender(ctx));
    }

    public fun magic(self: &Sword): u64 {
        self.magic
    }

    public fun strength(self: &Sword): u64 {
        self.strength
    }

    public fun swords_created(self: &Forge): u64 {
        self.swords_created
    }

    public entry fun sword_create(magic: u64, strength: u64, recipient: address, ctx: &mut TxContext) {
        // create a sword
        let sword = Sword {
            id: object::new(ctx),
            magic,
            strength,
        };
        // transfer the sword
        transfer::transfer(sword, recipient);
    }

    public entry fun sword_transfer(sword: Sword, recipient: address, _ctx: &mut TxContext) {
        // transfer the sword
        transfer::transfer(sword, recipient);
    }

    #[test]
    fun test_sword_create() {
        use sui::tx_context;

        // create a dummy TxContext for testing
        let ctx = tx_context::dummy();

        // create a sword
        let sword = Sword {
            id: object::new(&mut ctx),
            magic: 42,
            strength: 7
        };

        // check if accessor functions return correct values
        assert!(magic(&sword) == 42 && strength(&sword) == 7, 1);

        // post-process
        let dummy_address = @0xCAFE;
        transfer::transfer(sword, dummy_address);
    }

    #[test_only]
    use sui::test_scenario;
    #[test]
    fun test_sword_transactions() {
        let admin = @0xABBA;
        let initial_owner = @0xCAFE;
        let final_owner = @0xFACE;

        let scenario = &mut test_scenario::begin(&admin);
        {
            sword_create(42, 7, initial_owner, test_scenario::ctx(scenario));
        };
        test_scenario::next_tx(scenario, &initial_owner);
        {
            let sword = test_scenario::take_owned<Sword>(scenario);
            sword_transfer(sword, final_owner, test_scenario::ctx(scenario))
        };
        test_scenario::next_tx(scenario, &final_owner);
        {
            let sword = test_scenario::take_owned<Sword>(scenario);
            assert!(magic(&sword) == 42, 1);
            assert!(strength(&sword) == 7, 1);
            test_scenario::return_owned(scenario, sword)
        }
    }
}
