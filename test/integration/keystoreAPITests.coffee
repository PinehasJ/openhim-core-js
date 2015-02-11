should = require "should"
request = require "supertest"
testUtils = require "../testUtils"
auth = require("../testUtils").auth
server = require "../../lib/server"
Keystore = require('../../lib/model/keystore').Keystore
Certificate = require('../../lib/model/keystore').Certificate
sinon = require "sinon"
fs = require 'fs'
path = require 'path'

describe 'API Integration Tests', ->

  describe 'Keystore API Tests', ->

    authDetails = {}

    before (done) ->
      auth.setupTestUsers (err) ->
        server.start null, null, 8080, null, null, false, ->
          done()

    after (done) ->
      auth.cleanupTestUsers (err) ->
        server.stop ->
          done()

    beforeEach (done) ->
      authDetails = auth.getAuthDetails()
      Keystore.remove {}, ->
        done()

    afterEach (done) ->
      testUtils.cleanupTestKeystore ->
      	done()

    it "Should fetch the current HIM server certificate", (done) ->
      testUtils.setupTestKeystore (keystore) ->
        request("https://localhost:8080")
          .get("/keystore/cert")
          .set("auth-username", testUtils.rootUser.email)
          .set("auth-ts", authDetails.authTS)
          .set("auth-salt", authDetails.authSalt)
          .set("auth-token", authDetails.authToken)
          .expect(200)
          .end (err, res) ->
            if err
              done err
            else
              res.body.data.should.be.exactly keystore.cert.data
              res.body.commonName.should.be.exactly 'localhost'
              done()

    it "Should not allow a non-admin user to fetch the current HIM server certificate", (done) ->
      testUtils.setupTestKeystore ->
        request("https://localhost:8080")
          .get("/keystore/cert")
          .set("auth-username", testUtils.nonRootUser.email)
          .set("auth-ts", authDetails.authTS)
          .set("auth-salt", authDetails.authSalt)
          .set("auth-token", authDetails.authToken)
          .expect(403)
          .end (err, res) ->
            if err
              done err
            else
              done()

    it "Should fetch the current trusted ca certificates", (done) ->
      testUtils.setupTestKeystore (keystore) ->
        request("https://localhost:8080")
          .get("/keystore/ca")
          .set("auth-username", testUtils.rootUser.email)
          .set("auth-ts", authDetails.authTS)
          .set("auth-salt", authDetails.authSalt)
          .set("auth-token", authDetails.authToken)
          .expect(200)
          .end (err, res) ->
            if err
              done err
            else
              res.body.should.be.instanceof(Array).and.have.lengthOf(2);
              res.body[0].should.have.property 'commonName', keystore.ca[0].commonName
              res.body[1].should.have.property 'commonName', keystore.ca[1].commonName
              done()

    it "Should not allow a non-admin user to fetch the current trusted ca certificates", (done) ->
      testUtils.setupTestKeystore ->
        request("https://localhost:8080")
          .get("/keystore/ca")
          .set("auth-username", testUtils.nonRootUser.email)
          .set("auth-ts", authDetails.authTS)
          .set("auth-salt", authDetails.authSalt)
          .set("auth-token", authDetails.authToken)
          .expect(403)
          .end (err, res) ->
            if err
              done err
            else
              done()

    it "Should fetch a ca certificate by id", (done) ->
      testUtils.setupTestKeystore (keystore) ->
        request("https://localhost:8080")
          .get("/keystore/ca/#{keystore.ca[0]._id}")
          .set("auth-username", testUtils.rootUser.email)
          .set("auth-ts", authDetails.authTS)
          .set("auth-salt", authDetails.authSalt)
          .set("auth-token", authDetails.authToken)
          .expect(200)
          .end (err, res) ->
            if err
              done err
            else
              res.body.should.have.property 'commonName', keystore.ca[0].commonName
              res.body.should.have.property 'data', keystore.ca[0].data
              done()

    it "Should not allow a non-admin user to fetch a ca certificate by id", (done) ->
      testUtils.setupTestKeystore ->
        request("https://localhost:8080")
          .get("/keystore/ca/1234")
          .set("auth-username", testUtils.nonRootUser.email)
          .set("auth-ts", authDetails.authTS)
          .set("auth-salt", authDetails.authSalt)
          .set("auth-token", authDetails.authToken)
          .expect(403)
          .end (err, res) ->
            if err
              done err
            else
              done()

    it "Should add a new server certificate", (done) ->
      testUtils.setupTestKeystore (keystore) ->
        postData = { cert: fs.readFileSync('test/resources/server-tls/cert.pem').toString() }
        request("https://localhost:8080")
          .post("/keystore/cert")
          .set("auth-username", testUtils.rootUser.email)
          .set("auth-ts", authDetails.authTS)
          .set("auth-salt", authDetails.authSalt)
          .set("auth-token", authDetails.authToken)
          .send(postData)
          .expect(201)
          .end (err, res) ->
            if err
              done err
            else
              Keystore.findOne {}, (err, keystore) ->
                done(err) if err
                keystore.cert.data.should.be.exactly postData.cert
                keystore.cert.commonName.should.be.exactly 'localhost'
                keystore.cert.organization.should.be.exactly 'Jembi Health Systems NPC'
                done()

    it "Should not allow a non-admin user to add a new server certificate", (done) ->
      testUtils.setupTestKeystore (keystore) ->
        postData = { cert: fs.readFileSync('test/resources/server-tls/cert.pem').toString() }
        request("https://localhost:8080")
          .post("/keystore/cert")
          .set("auth-username", testUtils.nonRootUser.email)
          .set("auth-ts", authDetails.authTS)
          .set("auth-salt", authDetails.authSalt)
          .set("auth-token", authDetails.authToken)
          .send(postData)
          .expect(403)
          .end (err, res) ->
            if err
              done err
            else
              done()

    it "Should add a new server key", (done) ->
      testUtils.setupTestKeystore (keystore) ->
        postData = { key: fs.readFileSync('test/resources/server-tls/key.pem').toString() }
        request("https://localhost:8080")
          .post("/keystore/key")
          .set("auth-username", testUtils.rootUser.email)
          .set("auth-ts", authDetails.authTS)
          .set("auth-salt", authDetails.authSalt)
          .set("auth-token", authDetails.authToken)
          .send(postData)
          .expect(201)
          .end (err, res) ->
            if err
              done err
            else
              Keystore.findOne {}, (err, keystore) ->
                done(err) if err
                keystore.key.should.be.exactly postData.key
                done()

    it "Should not alllow a non-admin user to add a new server key", (done) ->
      testUtils.setupTestKeystore (keystore) ->
        postData = { key: fs.readFileSync('test/resources/server-tls/key.pem').toString() }
        request("https://localhost:8080")
          .post("/keystore/key")
          .set("auth-username", testUtils.nonRootUser.email)
          .set("auth-ts", authDetails.authTS)
          .set("auth-salt", authDetails.authSalt)
          .set("auth-token", authDetails.authToken)
          .send(postData)
          .expect(403)
          .end (err, res) ->
            if err
              done err
            else
              done()

    it "Should add a new trusted certificate", (done) ->
      testUtils.setupTestKeystore (keystore) ->
        postData = { cert: fs.readFileSync('test/resources/trust-tls/cert1.pem').toString() }
        request("https://localhost:8080")
          .post("/keystore/ca/cert")
          .set("auth-username", testUtils.rootUser.email)
          .set("auth-ts", authDetails.authTS)
          .set("auth-salt", authDetails.authSalt)
          .set("auth-token", authDetails.authToken)
          .send(postData)
          .expect(201)
          .end (err, res) ->
            if err
              done err
            else
              Keystore.findOne {}, (err, keystore) ->
                done(err) if err
                keystore.ca.should.be.instanceOf(Array).and.have.lengthOf 3
                keystore.ca[2].data.should.be.exactly postData.cert
                keystore.ca[2].commonName.should.be.exactly 'trust1.org'
                keystore.ca[2].organization.should.be.exactly 'Trusted Inc.'
                done()

    it "Should not allow a non-admin user to add a new trusted certificate", (done) ->
      testUtils.setupTestKeystore (keystore) ->
        postData = { cert: fs.readFileSync('test/resources/trust-tls/cert1.pem').toString() }
        request("https://localhost:8080")
          .post("/keystore/ca/cert")
          .set("auth-username", testUtils.nonRootUser.email)
          .set("auth-ts", authDetails.authTS)
          .set("auth-salt", authDetails.authSalt)
          .set("auth-token", authDetails.authToken)
          .send(postData)
          .expect(403)
          .end (err, res) ->
            if err
              done err
            else
              done()

    it "Should add each certificate in a certificate chain", (done) ->
      testUtils.setupTestKeystore (keystore) ->
        postData = { cert: fs.readFileSync('test/resources/chain.pem').toString() }
        request("https://localhost:8080")
          .post("/keystore/ca/cert")
          .set("auth-username", testUtils.rootUser.email)
          .set("auth-ts", authDetails.authTS)
          .set("auth-salt", authDetails.authSalt)
          .set("auth-token", authDetails.authToken)
          .send(postData)
          .expect(201)
          .end (err, res) ->
            if err
              done err
            else
              Keystore.findOne {}, (err, keystore) ->
                done(err) if err
                keystore.ca.should.be.instanceOf(Array).and.have.lengthOf 4
                keystore.ca[2].commonName.should.be.exactly 'domain.com'
                keystore.ca[3].commonName.should.be.exactly 'ca.marc-hi.ca'
                done()

    it "Should remove a ca certificate by id", (done) ->
      testUtils.setupTestKeystore (keystore) ->
        request("https://localhost:8080")
          .del("/keystore/ca/#{keystore.ca[0]._id}")
          .set("auth-username", testUtils.rootUser.email)
          .set("auth-ts", authDetails.authTS)
          .set("auth-salt", authDetails.authSalt)
          .set("auth-token", authDetails.authToken)
          .expect(200)
          .end (err, res) ->
            if err
              done err
            else
              Keystore.findOne {}, (err, keystore) ->
                done(err) if err
                keystore.ca.should.be.instanceOf(Array).and.have.lengthOf 1
                done()

    it "Should not allow a non-admin user to remove a ca certificate by id", (done) ->
      testUtils.setupTestKeystore ->
        request("https://localhost:8080")
          .del("/keystore/ca/1234")
          .set("auth-username", testUtils.nonRootUser.email)
          .set("auth-ts", authDetails.authTS)
          .set("auth-salt", authDetails.authSalt)
          .set("auth-token", authDetails.authToken)
          .expect(403)
          .end (err, res) ->
            if err
              done err
            else
              done()