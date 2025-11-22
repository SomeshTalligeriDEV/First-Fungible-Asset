module FACoin::fa_coin {
    use aptos_framework::fungible_asset::{Self, MintRef, TransferRef, BurnRef, Metadata};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;
    use std::error;
    use std::signer;
    use std::string::{Self, utf8};
    use std::option;

    const ENOT_OWNER: u64 = 1;

    const ASSET_NAME: vector<u8> = b"Shadow Dev Coin";
    const ASSET_SYMBOL: vector<u8> = b"SD Coin";

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct ManagedFungibleAsset has key {
        mint_ref: MintRef,
        transfer_ref: TransferRef,
        burn_ref: BurnRef
    }

    fun init_module(admin: &signer) {
        let constructor_ref = &object::create_named_object(admin, ASSET_SYMBOL);

        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            option::none(),
            utf8(ASSET_NAME), // FIXED
            utf8(ASSET_SYMBOL),
            8,
            utf8(b"http://example.com/icon.png"),
            utf8(b"http://example.com")
        );

        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
        let metadata_signer = object::generate_signer(constructor_ref);

        move_to(
            &metadata_signer,
            ManagedFungibleAsset { mint_ref, transfer_ref, burn_ref }
        );
    }

    #[view]
    public fun get_metadata(): Object<Metadata> {
        let asset_address = object::create_object_address(&@FACoin, ASSET_SYMBOL);
        object::address_to_object<Metadata>(asset_address)
    }

    #[view]
    public fun get_name(): string::String {
        let metadata = get_metadata();
        fungible_asset::name(metadata)
    }

    public entry fun mint(admin: &signer, to: address, amount: u64) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let refs = authorized_borrow_refs(admin, asset);
        let wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);

        let coins = fungible_asset::mint(&refs.mint_ref, amount);
        fungible_asset::deposit_with_ref(&refs.transfer_ref, wallet, coins);
    }

    public entry fun transfer(
        admin: &signer,
        from: address,
        to: address,
        amount: u64
    ) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let refs = authorized_borrow_refs(admin, asset);

        let from_wallet = primary_fungible_store::primary_store(from, asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);

        fungible_asset::transfer_with_ref(
            &refs.transfer_ref,
            from_wallet,
            to_wallet,
            amount
        );
    }

    public entry fun burn(admin: &signer, from: address, amount: u64) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let refs = authorized_borrow_refs(admin, asset);

        let wallet = primary_fungible_store::primary_store(from, asset);

        fungible_asset::burn_from(&refs.burn_ref, wallet, amount);
    }

    public entry fun freeze_account(admin: &signer, account: address) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let refs = authorized_borrow_refs(admin, asset);
        let wallet = primary_fungible_store::ensure_primary_store_exists(account, asset);
        fungible_asset::set_frozen_flag(&refs.transfer_ref, wallet, true);
    }

    public entry fun unfreeze_account(admin: &signer, account: address) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let refs = authorized_borrow_refs(admin, asset);
        let wallet = primary_fungible_store::ensure_primary_store_exists(account, asset);
        fungible_asset::set_frozen_flag(&refs.transfer_ref, wallet, false);
    }

    inline fun authorized_borrow_refs(
        owner: &signer, asset: Object<Metadata>
    ): &ManagedFungibleAsset {
        assert!(
            object::is_owner(asset, signer::address_of(owner)),
            error::permission_denied(ENOT_OWNER)
        );
        borrow_global<ManagedFungibleAsset>(object::object_address(&asset))
    }

    #[test(creator = @FACoin)]
    fun test_basic_flow(creator: &signer) acquires ManagedFungibleAsset {
        init_module(creator);
        let creator_address = signer::address_of(creator);
        let aaron = @0xface;

        mint(creator, creator_address, 100);
        let asset = get_metadata();
        assert!(primary_fungible_store::balance(creator_address, asset) == 100, 4);

        freeze_account(creator, creator_address);
        assert!(primary_fungible_store::is_frozen(creator_address, asset), 5);

        transfer(creator, creator_address, aaron, 10);
        assert!(primary_fungible_store::balance(aaron, asset) == 10, 6);

        unfreeze_account(creator, creator_address);
        assert!(!primary_fungible_store::is_frozen(creator_address, asset), 7);

        burn(creator, creator_address, 90);
    }

    #[test(creator = @FACoin, user = @0xface)]
    #[expected_failure]
    fun test_permission_denied(creator: &signer, user: &signer) acquires ManagedFungibleAsset {
        init_module(creator);
        let creator_address = signer::address_of(creator);
        mint(user, creator_address, 100);
    }
}

