content = open('lib/screens/welcome_seller_screen.dart').read()
content = content.replace('onPressed: ()', 'onPressed: () { if (phoneController.text.length != 10) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter valid 10-digit phone number"))); return; } ')
open('lib/screens/welcome_seller_screen.dart','w').write(content)
print('done welcome')
