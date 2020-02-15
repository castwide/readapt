# Readapt

A Ruby debugger that supports the [Debug Adapter Protocol](https://microsoft.github.io/debug-adapter-protocol/specification).

*This gem is currently in early development*.

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
