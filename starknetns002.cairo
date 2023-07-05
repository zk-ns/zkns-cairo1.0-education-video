#[contract]
mod StarknetNS {
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use starknet::get_block_timestamp;
    use traits::TryInto;
    use traits::Into;
    use option::OptionTrait;
    use zeroable::Zeroable;

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
        let result_str = add_suffix(_str);
        let _address: ContractAddress = ns_to_address::read(result_str);
        let str: felt252 = myns::read(caller);
        assert(str == 0, 'ns already register');
        assert(_address.is_zero(), 'address already register');
        myns::write(caller, result_str);
        ns_to_address::write(result_str, caller);
        ns_to_time::write(result_str, get_block_timestamp() + _year * 365 * 24 * 3600);
        total_ns::write(total_ns::read() + 1);
    }

    // a: 97
    // aa: 24929 97*256 + 97
    // aaa: 6381921 (97*256 + 97)*256 +97
    #[view]
    fn add_suffix(_str: felt252) -> felt252{
       let str_new: u256 = _str.into();
       let add_point = str_new * 256 + 46;
       let add_s = add_point * 256 + 115;
       let add_t = add_s * 256 + 116;
       let add_a = add_t * 256 + 97;
       let add_r = add_a * 256 + 114;
       let add_k = add_r * 256 + 107;
       let _result: felt252 = add_k.try_into().unwrap();
       return _result;
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
