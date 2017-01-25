# http://arcturo.github.io/library/coffeescript/03_classes.html
class Module
  @extend: (obj) ->
    for key, value of obj when key not in ['extended', 'included']
      @[key] = value

    obj.extended?.apply(@)
    @

  @include: (obj) ->
    for key, value of obj when key not in ['extended', 'included']
      # Assign properties to the prototype
      @::[key] = value

    obj.included?.apply(@)
    @

module.exports = Module