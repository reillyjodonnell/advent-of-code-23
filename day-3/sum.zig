pub fn sum(comptime T: type, nums: []const T) u64 {
    var amount: u64 = 0;
    for (nums) |num| {
        amount += num;
    }
    return amount;
}
