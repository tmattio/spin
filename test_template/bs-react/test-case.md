# With Tailwind

```sh
$ export SPIN_PROJECT_NAME=demo && \
> export SPIN_USERNAME=user && \
> export SPIN_CSS_FRAMEWORK=TailwindCSS && \
> spin new bs-react _generated -d --ignore-config

🏗️  Creating a new project from bs-react in _generated
Done!

🎁  Installing packages. This might take a couple minutes.
Done!

🎉  Success! Your project is ready at _generated

Here are some example commands that you can run inside this directory:

  yarn start
    Start the development server.

  yarn build
    Bundle the app into static files for production.

  yarn test
    Start the test runner.

Happy hacking!
$ cd _generated && yarn test
...
$ rm -rf _generated
```

# Without Tailwind

```sh
$ export SPIN_PROJECT_NAME=demo && \
> export SPIN_USERNAME=user && \
> export SPIN_CSS_FRAMEWORK=None && \
> spin new bs-react _generated -d --ignore-config

🏗️  Creating a new project from bs-react in _generated
Done!

🎁  Installing packages. This might take a couple minutes.
Done!

🎉  Success! Your project is ready at _generated

Here are some example commands that you can run inside this directory:

  yarn start
    Start the development server.

  yarn build
    Bundle the app into static files for production.

  yarn test
    Start the test runner.

Happy hacking!
$ cd _generated && yarn test
...
$ rm -rf _generated
```
