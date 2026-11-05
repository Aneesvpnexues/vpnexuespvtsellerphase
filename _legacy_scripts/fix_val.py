content = open('lib/screens/welcome_seller_screen.dart').read()
content = content.replace('TextField(', 'TextField(validator: (v) => (v != null && v.length == 10) ? null : "Phone must be 10 digits",', 1)
open('lib/screens/welcome_seller_screen.dart','w').write(content)
print('added')
