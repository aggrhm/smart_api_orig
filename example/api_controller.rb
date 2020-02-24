class ApiController < ApplicationController
  include SmartAPI::ControllerHelper

  engine_path "/provider"

  default_serializer_name "BaseSerializer"

  # other abilities here:
  # - Perform rate limiting
  # - Augment RequestContext
  # - ...

end
