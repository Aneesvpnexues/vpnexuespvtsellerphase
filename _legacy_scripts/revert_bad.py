content = open('lib/screens/welcome_seller_screen.dart').read()
# Remove broken inserted block
bad = 'onPressed: () { if (phoneController.text.length != 10) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter valid 10-digit phone number"))); return; }  {'
good = 'onPressed: () {'
content = content.replace(bad, good)
open('lib/screens/welcome_seller_screen.dart','w').write(content)
print('reverted broken')
