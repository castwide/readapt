# Readapt

A Ruby debugger that supports the [Debug Adapter Protocol](https://microsoft.github.io/debug-adapter-protocol/specification).

**This project is no longer maintained.** As of Ruby 3, the native `rdbg` debugger is capable of connecting to debug adapters, so Readapt is no longer necessary. For Visual Studio Code, the [VSCode rdbg Ruby Debugger](https://marketplace.visualstudio.com/items?itemName=KoichiSasada.vscode-rdbg) is a solid alternative.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'readapt'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install readapt

## Usage

Run `readapt serve` to start the server. The default client connection is host 127.0.0.1, port 1234.

## Integrations

Plug-ins and extensions using Readapt are available for the following editors:

* **Visual Studio Code**
    * Marketplace: https://marketplace.visualstudio.com/items?itemName=castwide.ruby-debug
    * GitHub: https://github.com/castwide/vscode-ruby-debug

* **Eclipse**
    * Marketplace: https://marketplace.eclipse.org/content/ruby-solargraph
    * GitHub: https://github.com/PyvesB/eclipse-solargraph
