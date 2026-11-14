// Keep the fast path exact on the VM and JavaScript; avoid 64-bit overflow.
const _safeInteger = 9007199254740991;

int scaledFloor(int amount, int part, int whole) {
  if (amount >= 0 &&
      part >= 0 &&
      whole > 0 &&
      (part == 0 || amount <= _safeInteger ~/ part)) {
    return amount * part ~/ whole;
  }
  return (BigInt.from(amount) * BigInt.from(part) ~/ BigInt.from(whole))
      .toInt();
}

int scaledCeil(int amount, int part, int whole) {
  if (amount >= 0 &&
      part >= 0 &&
      whole > 0 &&
      whole <= _safeInteger &&
      (part == 0 || amount <= (_safeInteger - whole + 1) ~/ part)) {
    return (amount * part + whole - 1) ~/ whole;
  }
  return ((BigInt.from(amount) * BigInt.from(part) + BigInt.from(whole - 1)) ~/
          BigInt.from(whole))
      .toInt();
}
