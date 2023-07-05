use starknet::ContractAddress;

#[abi]
trait IERC20 {
    #[view]
    fn name() -> felt252;

    #[view]
    fn symbol() -> felt252;

    #[view]
    fn decimals() -> u8;

    #[view]
    fn total_supply() -> u256;

    #[view]
    fn balance_of(account: ContractAddress) -> u256;

    #[view]
    fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256;

    #[external]
    fn transfer(recipient: ContractAddress, amount: u256) -> bool;

    #[external]
    fn transfer_from(sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;

    #[external]
    fn transferFrom(sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;

    #[external]
    fn approve(spender: ContractAddress, amount: u256) -> bool;
}


#[contract]
mod StarknetNS {
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use starknet::get_block_timestamp;
    use traits::TryInto;
    use traits::Into;
    use option::OptionTrait;
    use zeroable::Zeroable;
    use super::IERC20DispatcherTrait;
    use super::IERC20Dispatcher;
    use starknet::get_contract_address;
    use starknet::contract_address_const;

    struct Storage {
        myns: LegacyMap::<ContractAddress, felt252>,
        ns_to_address: LegacyMap::<felt252, ContractAddress>,
        ns_to_time: LegacyMap::<felt252, u64>,
        total_ns: u256,
        price: u256,
        eth20_address: ContractAddress,
        owner: ContractAddress,
    }

    #[constructor]
    fn constructor(_owner: ContractAddress) {
       owner::write(_owner);
       price::write(1000000000000000);
       total_ns::write(0);
    }

    #[external]
    fn set_ns(_str: felt252, _year: u256, version: u8) {
        assert(_year >=1, 'year not allow');
        assert(_year <=5, 'year not allow');
        let caller = get_caller_address();
        let _price = computer_price(_str, _year, price::read());
        let result_str = add_suffix(_str);
        let _address: ContractAddress = ns_to_address::read(result_str);
        let str: felt252 = myns::read(caller);
        assert(str == 0, 'ns already register');
        assert(_address.is_zero(), 'address already register');
        let thisaddress: ContractAddress = get_contract_address();
        if(version == 0){
           IERC20Dispatcher { contract_address: eth20_address::read() }.transferFrom(caller, thisaddress, _price);  
        }else{
           IERC20Dispatcher { contract_address: eth20_address::read() }.transfer_from(caller, thisaddress, _price);  
        }
        
        myns::write(caller, result_str);
        ns_to_address::write(result_str, caller);
        let years: u64 = (_year.try_into().unwrap()).try_into().unwrap();
        ns_to_time::write(result_str, get_block_timestamp() + years * 365 * 24 * 3600);
        total_ns::write(total_ns::read() + 1);
    }

    #[external]
    fn change_price(_price: u256){
       let caller: ContractAddress = get_caller_address();
       assert(owner::read() == caller, 'not owner');
       price::write(_price);
    }

    #[external]
    fn change_owner(_owner: ContractAddress){
       let caller: ContractAddress = get_caller_address();
       assert(owner::read() == caller, 'not owner');
       owner::write(_owner);
    }

    #[external]
    fn set_contract_address(_ethaddress: ContractAddress){
       let caller: ContractAddress = get_caller_address();
       assert(owner::read() == caller, 'not owner');
       eth20_address::write(_ethaddress);
    }

    #[external]
    fn claim(_amount: u256){
       let caller: ContractAddress = get_caller_address();
       assert(owner::read() == caller, 'not owner');
       IERC20Dispatcher { contract_address: eth20_address::read() }.transfer(caller, _amount); 
    }

    #[external]
    fn cancle_ns(str: felt252){
       let caller: ContractAddress = get_caller_address();
       assert(owner::read() == caller, 'not owner');
       let expire: u64 = ns_to_time::read(str);
       assert(expire > 0, 'wrong str');
       let now: u64 = get_block_timestamp();
       assert(now >= expire, 'time not yet');
       ns_to_time::write(str, 0);
       let addr: ContractAddress = ns_to_address::read(str);
       myns::write(addr, 0);
       ns_to_address::write(str, contract_address_const::<0>());
       if(total_ns::read() >0){
         total_ns::write(total_ns::read() -1);
       }
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
    fn get_amount_of_chars(len: u64, num: u256, str: felt252) -> u64{
       let str_new: u256 = str.into();
       if(num * 255 >= str_new){
          return len;
       }else if(len > 5){
          return len;
       }else{
          let _num = num * 255;
          let _len = len + 1;
          let next = get_amount_of_chars(_len, _num, str);
          return next;
       }

    }

    #[view]
    fn get_amount_of_chars2(str: felt252) -> u64{
       let str_new: u64 = str.try_into().unwrap();
       if(str_new == 0){
         return 0;
       }

       let p = str_new / 255_u64;
       let _p: felt252 = p.into();
       let next = get_amount_of_chars2(_p);
       return 1 + next;
    }

    #[view]
    fn computer_price(str: felt252, _year: u256, nsprice: u256) -> u256 {
       let mut _price: u256 = nsprice * _year;
       let len: u64 = get_amount_of_chars(1, 1, str);
       assert(len >=2, 'chars at least 2');
       if(len < 3){
          _price = _price * 5;
       }else if(len == 3){
          _price = _price * 4;
       }else if(len == 4){
          _price = _price * 3;
       }else if(len == 5){
          _price = _price * 2;
       }

       return _price;

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
