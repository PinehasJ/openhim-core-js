'use strict'

import {ChannelModelAPI} from '../model/channels'
import { RoleModelAPI } from '../model/role'

export function inGroup(group, user) {
  return user.groups.indexOf(group) >= 0
}

/**
 * A promise returning function that returns the list
 * of viewable channels for a user.
 */
export function getUserViewableChannels(user) {
  return RoleModelAPI.find({name: {$in: user.groups}}, {permissions: {"channel-view-all": 1, "channel-view-specified": 1}}).then(roles => {
    if (roles.find(role => role.permissions['channel-view-all'])) {
      return ChannelModelAPI.find({}).exec()
    }
    const specifiedChannels = roles.reduce((prev, curr) =>
      prev.concat(curr.permissions['channel-view-specified']),
      []
    )
    return ChannelModelAPI.find({_id: {$in: specifiedChannels}}).exec()
  })
}

/**
 * A promise returning function that returns the list
 * of rerunnable channels for a user.
 */
export function getUserRerunableChannels(user) {
  return RoleModelAPI.find({name: {$in: user.groups}}, {permissions: {"transaction-rerun-all": 1, "transaction-rerun-specified": 1}}).then(roles => {
    if (roles.find(role => role.permissions['transaction-rerun-all'])) {
      return ChannelModelAPI.find({}).exec()
    }
    const specifiedChannels = roles.reduce((prev, curr) =>
      prev.concat(curr.permissions['transaction-rerun-specified']),
      []
    )
    return ChannelModelAPI.find({_id: {$in: specifiedChannels}}).exec()
  })
}
