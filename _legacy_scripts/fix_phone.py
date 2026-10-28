content = open('lib/screens/welcome_seller_screen.dart').read()
content = content.replace('onPressed: () {', 'onPressed: () { if (_phone.text.length != 10) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter valid 10-digit phone number"))); return; } ', 1)
open('lib/screens/welcome_seller_screen.dart','w').write(content)
print('done')
