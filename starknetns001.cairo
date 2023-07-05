#[contract]
mod StarknetNS {
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use starknet::get_block_timestamp;

    struct Storage {
        myns: LegacyMap::<ContractAddress, felt252>,
        ns_to_address: LegacyMap::<felt252, ContractAddress>,
        ns_to_time: LegacyMap::<felt252, u64>,
        total_ns: u256,
    }

    #[constructor]
    fn constructor() {
    }

    #[external]
    fn set_ns(_str: felt252, _year: u64) {
        assert(_year >=1, 'year not allow');
        assert(_year <=5, 'year not allow');
        let caller = get_caller_address();
        myns::write(caller, _str);
        ns_to_address::write(_str, caller);
        ns_to_time::write(_str, get_block_timestamp() + _year * 365 * 24 * 3600);
        total_ns::write(total_ns::read() + 1);
    }

    #[view]
    fn get_name(_address: ContractAddress) -> felt252 {
        let name = myns::read(_address);
        return name;
    }

    #[view]
    fn get_address(_str: felt252) -> ContractAddress {
        let _address = ns_to_address::read(_str);
        return _address;
    }

    #[view]
    fn get_ns_time(_str: felt252) -> u64 {
        let _time = ns_to_time::read(_str);
        return _time;
    }

     #[view]
    fn get_total_ns() -> u256 {
        return total_ns::read();
    }


}
