content = open('lib/screens/otp_screen.dart').read()
content = content.replace('onPressed: ()', 'onPressed: () { if (phoneController.text.length != 10) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter valid 10-digit phone number"))); return; } ')
open('lib/screens/otp_screen.dart','w').write(content)
print('done')
