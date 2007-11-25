# $Id$
require 'appscript'
class Application
  include Appscript

  def get_app
    app(@appname)
  end
end
