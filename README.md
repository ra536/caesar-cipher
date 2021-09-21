# Caesar Cipher in AT&T Assembly

## Setup
To clone this project, run:
```bash
git clone git@github.com:ra536/caesar-cipher.git
```

## Extended Setup for Class
GitHub no longer supports regular password authentication, so we'll have to use SSH.

### SSH Key
Generate an SSH key by running:
```bash
ssh-keygen -t ed25519 -C "your-GitHub-email-address"
```
Keep hitting Enter until the command completes.

### SSH Config
Next, create a file:
```bash
touch ~/.ssh/config
```
and add the contents:
```
Host *
AddKeysToAgent yes
IdentityFile ~/.ssh/id_ed25519
```

Finally, add the SSH key to your config:
```bash
chmod 600 ~/.ssh/config
ssh-add ~/.ssh/id_ed25519
```

### Linking with GitHub
https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account

## Usage
To compile the program, type: 
```bash
./compile
```

This will assemble and link the final executable.

From there, simply run:
```bash
./caesar
```

## Credits
Contributors: Robert Argasinski, Alexander Cline, Nishaant Goswamy
