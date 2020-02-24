Provider::Engine.routes.draw do

  mount_api_endpoints("/api/v1", controller: "api/api", engine_path: "/provider") do

    model_endpoints_for("User", crud: true) do
      # --- added by default
      # get  "/users", class_action: "index_as_action!"
      # post  "/user", action: "update_as_action!" # /user?id=123
      # delete "/user", action: "delete_as_action!"
      # ---
      post "/users/do_something", class_action: "do_something_as_action!"
    end

  end

end

