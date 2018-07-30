pragma solidity ^0.4.23;

contract Random {
  function random(address callee, uint salt) internal view returns(uint) {
    return uint(keccak256(abi.encodePacked(blockhash(block.number), now, callee, salt)));
  }

  // accepts already generated random number and limit it to upper value
  function random(uint rnd, uint upper) internal pure returns (uint) {
    if (upper == 0) {
      return 0;
    }

    return rnd % upper;
  }

  function random(uint upper, address callee, uint salt) internal view returns(uint) {
    if (upper == 0) {
      return 0;
    }

    return random(callee, salt) % upper;
  }

  function random(uint min, uint max, address callee, uint salt) internal view returns (uint) {
    require(min < max);
    return min + random(max - min, callee, salt);
  }

  function random(uint rnd, uint rangeSize, uint exp) internal pure returns(uint) {
    uint d = 10**exp;
    if (rangeSize == 0 || d == 0) return 0;
    return rnd % (rangeSize * d) / d;
  }

  function random(uint rnd, uint upper, uint rangeSize, uint exp) internal pure returns (uint) {
    if (upper == 0) {
      return 0;
    }

    return random(rnd, rangeSize, exp) % upper;
  }

  function random(uint rnd, uint min, uint max, uint rangeSize, uint exp) internal pure returns (uint) {
    if (min >= max) return 0;
    return min + random(rnd, rangeSize, exp) % (max - min);
  }

  // pick or generate new number in [0..1 000 000) 
  function extract(uint rnd, uint min, uint max, uint rangeSize, uint exp) internal pure returns(uint, uint, uint) {
      if (exp == 71) {
          // generate new random based on current
          rnd = uint(keccak256(rnd));
          exp = 0;
      }
      return (min + random(rnd, rangeSize, exp) % (max - min), rnd, exp+1);
  } 

  function getRandomInRange(uint rnd, uint min, uint max) internal pure returns(uint) {
    if (max <= min) {
      return min;
    }
    return min + rnd % (max - min);
  }

  function getRandom(uint seed) internal pure returns(uint) {
    return uint(keccak256(seed));
  }

  function getRandom(uint seed, uint salt) internal pure returns(uint) {
      return uint(keccak256(abi.encodePacked(seed, salt)));
  }

  function getRandom(uint seed, uint salt, uint divider) internal pure returns(uint, uint) {
      uint rnd = uint(keccak256(abi.encodePacked(seed, salt)));
      return (rnd, rnd % divider);
  }
}