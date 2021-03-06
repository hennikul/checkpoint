class CheckpointV1 < Sinatra::Base

  helpers do
    def find_group_and_check_god_credentials(identifier)
      group = AccessGroup.where(:realm_id => current_realm.id).by_label_or_id(identifier).first
      halt 404, "No such group (#{identifier})" unless group
      check_god_credentials(group.realm_id)
      group
    end
  end

  # @apidoc
  # List all groups for the current realm.
  #
  # @category Checkpoint/AccessGroups
  # @path /api/checkpoint/v1/access_groups
  # @http GET
  # @example /api/checkpoint/v1/access_groups
  # @status 200 [JSON]

  get "/access_groups" do
    groups = AccessGroup.where(:realm_id => current_realm.id)
    pg :access_groups, :locals => { :access_groups => groups }
  end

  # @apidoc
  # Create a new group.
  #
  # @note Only for gods of the realm
  # @category Checkpoint/AccessGroups
  # @path /api/checkpoint/v1/access_groups/:label
  # @http POST
  # @optional [String] label A unique (within the realm) identifier for this group.
  # @example /api/checkpoint/v1/access_groups/secret_cabal
  # @status 201 [JSON]

  post "/access_groups/?:label?" do |label|
    check_god_credentials
    group = AccessGroup.create!(:realm => current_realm, :label => label)
    [201, pg(:access_group, :locals => {:access_group => group})]
  end

  # @apidoc
  # Create or update new group.
  #
  # @note Only for gods of the realm
  # @category Checkpoint/AccessGroups
  # @path /api/checkpoint/v1/access_groups/:label
  # @http PUT
  # @optional [String] label A unique (within the realm) identifier for this group.
  # @example /api/checkpoint/v1/access_groups/secret_cabal
  # @status 200 [JSON]
  # @status 201 [JSON]

  put "/access_groups/:label" do |label|
    check_god_credentials
    halt 400, "Invalid label" unless label =~ AccessGroup::LABEL_VALIDATOR
    group = AccessGroup.where(:realm_id => current_realm.id, :label => label).first
    group ||= AccessGroup.create!(:realm => current_realm, :label => label)
    [crud_http_status(group), pg(:access_group, :locals => {:access_group => group})]
  end

  # @apidoc
  # Retrieve metadata for a group.
  #
  # @category Checkpoint/AccessGroups
  # @path /api/checkpoint/v1/access_groups/:identifier
  # @http GET
  # @optional [String] identifier The id or label of the group.
  # @example /api/checkpoint/v1/access_groups/secret_cabal
  # @status 200 [JSON]

  get "/access_groups/:identifier" do |identifier|
    group = AccessGroup.where(:realm_id => current_realm.try(:id)).by_label_or_id(identifier).first
    halt 404 unless group
    pg :access_group, :locals => {:access_group => group}
  end

  # @apidoc
  # Delete a group.
  #
  # @note Only for gods of the realm.
  # @category Checkpoint/AccessGroups
  # @path /api/checkpoint/v1/api/checkpoint/v1/access_groups/:label
  # @http DELETE
  # @optional [String] identifier The id or label of the group.
  # @example /api/checkpoint/v1/access_groups/secret_cabal
  # @status 200 [JSON]

  delete "/access_groups/:identifier" do |identifier|
    group = find_group_and_check_god_credentials(identifier)
    group.destroy
    [204] # Success. No content..
  end

  # @apidoc
  # Add a member to the group.
  #
  # @note Only for gods of the realm.
  # @category Checkpoint/AccessGroups
  # @path /api/checkpoint/v1/access_groups/:access_group_identifier/memberships/:identity_id
  # @example /api/checkpoint/v1/access_groups/secret_cabal/memberships/1337
  # @http PUT
  # @optional [String] group_identifier The id or label of the group.
  # @optional [String] identity_id The id of the identity to add to the group.
  # @status 409 The identity is from a different realm than the group.
  # @status 204 [JSON]

  put "/access_groups/:access_group_identifier/memberships/:identity_id" do |group_identifier, identity_id|
    group = find_group_and_check_god_credentials(group_identifier)
    halt 204 if AccessGroupMembership.find_by_access_group_id_and_identity_id(group.id, identity_id)
    identity = Identity.find(identity_id)
    halt 409, "Identity realm does not match group realm" unless identity.realm_id == group.realm_id
    begin
      group_membership ||= AccessGroupMembership.create!(:access_group_id => group.id, :identity_id => identity_id)
    rescue PG::Error => e
      raise unless e.message =~ /violates.*group_membership_identity_uniqueness_index/
      halt 204 # This means someone beat us to it, but that is fine
    end
    [204] # Success. No content.
  end

  # @apidoc
  # Delete a group membership.
  #
  # @note Only for gods of the realm.
  # @category Checkpoint/AccessGroups
  # @path /api/checkpoint/v1/access_groups/:access_group_identifier/memberships/:identity_id
  # @example /api/checkpoint/v1/access_groups/secret_cabal/memberships/1337
  # @http DELETE
  # @optional [String] group_identifier The id or label of the group.
  # @optional [String] identity_id The id of the identity to add to the group.
  # @status 200 [JSON]

  delete "/access_groups/:access_group_identifier/memberships/:identity_id" do |group_identifier, identity_id|
    group = find_group_and_check_god_credentials(group_identifier)
    group_membership = AccessGroupMembership.find_by_access_group_id_and_identity_id(group.id, identity_id)
    group_membership.destroy if group_membership
    [204] # Success. No content..
  end

  # @apidoc
  # Add a path to the group.
  #
  # @note Only for gods of the realm.
  # @description The members of the group will be able to read all restricted content
  #   within the paths added to the group. I.e. if the path 'acme.secrets' is
  #   added to the group 'secret_cabal', its members will be able to read the secrets
  #   that are posted with the restricted flag within this path. This would include
  #   'post.secret_dossier:acme.secrets.top_secret.sinister_plans$3241'.
  # @category Checkpoint/AccessGroups
  # @path /api/checkpoint/v1/access_groups/:identifier/subtrees/:location
  # @example /api/checkpoint/v1/access_groups/acme/subtrees/acme.secrets
  # @http PUT
  # @optional [String] identifier The id or label of the group.
  # @optional [String] location The path to add to the group (i.e. acme.secrets).
  # @status 200 [JSON]

  put "/access_groups/:identifier/subtrees/:location" do |identifier, location|
    group = find_group_and_check_god_credentials(identifier)
    halt 204 if AccessGroupSubtree.find_by_access_group_id_and_location(group.id, location)
    subtree = AccessGroupSubtree.new(:access_group => group, :location => location)
    halt 403, "Subtree must be in same realm as group" unless subtree.location_path_matches_realm?
    subtree.save!
    [204] # Success. No content.
  end


  # @apidoc
  # Remove a path from a group.
  #
  # @note Only for gods of the realm
  # @description The path must be specified exactly as it has been added to the group.
  #   No magic will remove other granted locations that may fall within the subtree
  #   of the specified location.
  # @category Checkpoint/AccessGroups
  # @path /api/checkpoint/v1/access_groups/:access_group_identifier/subtrees/:location
  # @example /api/checkpoint/v1/access_groups/acme/subtrees/acme.secrets
  # @http DELETE
  # @optional [String] group_identifier The id or label of the group.
  # @optional [String] location The path to remove from the group (i.e. acme.secrets).
  # @status 200 [JSON]

  delete "/access_groups/:access_group_identifier/subtrees/:location" do |identifier, location|
    group = find_group_and_check_god_credentials(identifier)
    subtree = AccessGroupSubtree.find_by_access_group_id_and_location(group.id, location)
    subtree.destroy if subtree
    [204] # Success. No content.
  end

  # @apidoc
  # Get all memberships for a group.
  #
  # @category Checkpoint/AccessGroups
  # @path /api/checkpoint/v1/access_groups/:identifier/memberships
  # @example /api/checkpoint/v1/access_groups/secret_cabal/memberships
  # @http GET
  # @optional [String] identifier The id or label of the group.
  # @status 200 [JSON]

  get "/access_groups/:identifier/memberships" do |identifier|
    group = AccessGroup.where(:realm_id => current_realm.try(:id)).by_label_or_id(identifier).first
    halt 404, "No such group in this realm" unless group
    pg :memberships, :locals => { :memberships => group.memberships, :access_groups => nil}
  end

  # @apidoc
  # Get all group memberships for an identity.
  #
  # @category Checkpoint/AccessGroups
  # @path /api/checkpoint/v1/identities/:id/memberships
  # @example /api/checkpoint/v1/identities/1337/memberships
  # @http GET
  # @optional [String] id The id of the identity ('me' for current identity).
  # @status 404 No such identity in this realm.
  # @status 200 [JSON]

  get "/identities/:id/memberships" do |id|
    identity = (id == 'me') ? current_identity : Identity.find(id)
    halt 404, "No such identity in this realm" unless identity && identity.realm_id == current_realm.try(:id)
    memberships = AccessGroupMembership.where(:identity_id => identity.id).includes(:access_group)
    pg :memberships, :locals => { :memberships => memberships, :access_groups => memberships.map(&:access_group)}
  end

  # @apidoc
  # Ask if an identity has (restricted) access to a given path.
  #
  # @category Checkpoint/AccessGroups
  # @path /api/checkpoint/v1/identities/:id/access_to/:path
  # @example /api/checkpoint/v1/identities/1/access_to/a.b.c
  # @http GET
  # @required [String] id The id of the identity ('me' for current identity).
  # @required [String] path The path for which access status is being checked
  # @status 200 [JSON]
  get "/identities/:id/access_to/:path" do |id, path|
    identity = (id == 'me') ? current_identity : Identity.cached_find_by_id(id)
    unless identity && identity.realm_id == current_realm.try(:id)
      halt 200, {:access => {:granted => false, :path => path}}.to_json
    end

    paths = AccessGroup.paths_for_identity(identity.id)

    if paths.any? { |other| path[0..(other.length - 1)] == other }
      halt 200, {:access => {:granted => true, :path => path}}.to_json
    else
      halt 200, {:access => {:granted => false, :path => path}}.to_json
    end
  end

end
