String formatPhone(String input) {
  var phone = input.replaceAll(RegExp(r'\s+'), '');
  if (!phone.startsWith('+')) {
    phone = '+249' + phone;
  }
  return phone;
}
