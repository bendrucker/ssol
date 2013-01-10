SSOL Library
============

This is a work in progress designed to provide programatic access to the course management functionality within Columbia University's [SSOL](https://ssol.columbia.edu) (Student Services Online) via Ruby. Currently functionality is limited to reading data out of SSOL, but write methods are in the works. 

Guide
-----

To use the library, *require* it in your application and instantiate a new *SSOL* object using your UNI. The *SSOL* class requires your credentials to be passed in the form of a hash with keys *:id* and *:password*.
``` ruby
require "ssol.rb"
ssol = SSOL.new({:id => 'your_uni', :password => 'your_password'})
```

The *SSOL* class exposes the following public methods: 

- **`registration_appointments`:** Returns an *Array* of hashes with *:start* and *:end* keys. 
- **`registration_appointment?(time)`:** Returns true if the given *time* (defaults to Time.now) is a registration appointment
- **`query_class(query)`:** Searches for classes based on the provided *query* and returns an array of classes with all available attributes.

SSOL handles sessions in a very unusual and unpredictable way. This library is designed to make a string of requests to SSOL at one time. Any code that stored an *SSOL* object for use at a later time could create unpredictable results and would probably break. While it's certainly less efficient to create a new session every time the class is instantiated, it also eliminates login-related edge cases.

Dependencies
------------

All interaction with SSOL is handled by [Mechanize](https://github.com/sparklemotion/mechanize), an automated web interaction library for Ruby that uses [Nokogiri](https://github.com/sparklemotion/nokogiri) to parse HTML. Unlike [Selenium](http://seleniumhq.org), Mechanize is not a browser automation tool, which makes it much lighter. Run `gem install mechanize` to install. 


Roadmap
-------

The original motivation for creating this library was to solve the problem of limited class availability by automating class availability checks and registering when slots opened. I didn't need that this semester, so now this has become a side project for me. 

- Write methods, especially the ability to add and drop classes
- Read methods for:
	- The schedule and exams page, including the ability to render a schedule to .ics
	- Grades