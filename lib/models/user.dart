class User {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final bool optOut;

  User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    this.optOut = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobileNumber': mobileNumber,
      'optOut': optOut ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      mobileNumber: map['mobileNumber'],
      optOut: map['optOut'] == 1,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, firstName: $firstName, lastName: $lastName, email: $email, mobileNumber: $mobileNumber, optOut: $optOut}';
  }
}