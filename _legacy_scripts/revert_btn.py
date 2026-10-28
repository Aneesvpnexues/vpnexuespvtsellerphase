content = open('lib/screens/welcome_seller_screen.dart').read()
old = 'onPressed: () { if (_phone.text.length != 10) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter valid 10-digit phone number"))); return; } '
new = 'onPressed: () { '
content = content.replace(old, new)
open('lib/screens/welcome_seller_screen.dart','w').write(content)
print('done')
