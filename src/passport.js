import _ from 'lodash'
import passport from 'koa-passport'
import * as passportLocal from 'passport-local'
import * as passportHttp from 'passport-http'
import * as passportOpenid from 'passport-openidconnect';

import MongooseStore from './middleware/sessionStore'
import {local, basic, openid} from './protocols'
import {UserModelAPI, PassportModelAPI} from './model'
import {config} from './config'

/**
 * Load Strategies: Local, Basic and Openid
 *
 */
passport.loadStrategies = function () {
  const {keycloak} = config.api

  let strategies = {
    local: {
      strategy: passportLocal.Strategy
    },
    basic: {
      strategy: passportHttp.BasicStrategy,
      protocol: 'basic'
    },
    openid: {
      name: 'Keycloak',
      protocol: 'openid',
      strategy: passportOpenid.Strategy,
      options: {
        issuer: keycloak.url,
        authorizationURL: `${keycloak.url}/protocol/openid-connect/auth`,
        tokenURL: `${keycloak.url}/protocol/openid-connect/token`,
        userInfoURL: `${keycloak.url}/protocol/openid-connect/userinfo`,
        clientID: keycloak.clientId,
        clientSecret: keycloak.clientSecret,
        callbackURL: keycloak.callbackUrl,
        scope: keycloak.scope,
        sessionKey: "openid_session_key",
        passReqToCallback: true,
        profile: true,
        store: new MongooseStore()
      }
    }
  }

  _.each(
    strategies,
    _.bind(async function (strat, key) {
      let Strategy

      if (key === 'local') {
        Strategy = strat.strategy
        passport.use(
          new Strategy(
            async (username, password, done) =>
              await local.login(username, password, done)
          )
        )
      } else if (key === 'basic') {
        Strategy = strat.strategy
        passport.use(
          new Strategy(
            async (username, password, done) =>
              await basic.login(username, password, done)
          )
        )
      } else if (key === 'openid') {
        Strategy = strat.strategy
        passport.use(new Strategy(strat.options, openid.login))
      }
    }, passport)
  )
}

/**
 * Serialize User: used the email to be stored in the session
 *
 */
passport.serializeUser(function (user, next) {
  next(null, user.email)
})

/**
 * Deserialize User
 *
 */
passport.deserializeUser(async function (email, next) {
  try {
    const user = await UserModelAPI.findOne({
      email
    })
    next(null, user)
  } catch (err) {
    next(err, null)
  }
})

export default passport
