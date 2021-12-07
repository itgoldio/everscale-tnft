pragma ton-solidity ^0.47.0;

/**
    Reserved codes - 100-199
 */
library DataErrors {
    uint8 constant value_is_empty = 101;
    uint8 constant sender_is_not_root = 102;
    uint8 constant value_less_than_required = 103;
    uint8 constant sender_is_not_owner = 104;
}
