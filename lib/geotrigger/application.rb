module Geotrigger

  class Application < Model

    def permissions
      post 'application/permissions'
    end

    def permissions= perms
      post 'application/permissions/update', perms
    end

    def devices params = {}
      post_list 'devices', params
    end

    def tags params = {}
      post_list 'tags', params
    end

    def triggers params = {}
      post_list 'triggers', params
    end

  end

end
