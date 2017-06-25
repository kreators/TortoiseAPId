
import Foundation

fileprivate struct refreshTokenModel {
    var id: String
    var refreshToken: String
    var expiresIn: Int
}

fileprivate struct oAuthKeyModel {
    var id: String
    var oAuthKey: String
    var expiresAt: TimeInterval
}

fileprivate var refreshTokens = [refreshTokenModel]()
fileprivate var oAuthKeys = [oAuthKeyModel]()

// MARK: - oAuthKey

func updateoAuthKey(id: String, oAuthKey: String, expiresAt: TimeInterval) {
    var oAuthKeyIndex = -1
    for (index, element) in oAuthKeys.enumerated() {
        if element.id == id {
            oAuthKeyIndex = index
            break
        }
    }
    if oAuthKeyIndex == -1 {
        oAuthKeys.append(oAuthKeyModel(id: id, oAuthKey: oAuthKey, expiresAt: expiresAt))
    } else {
        oAuthKeys[oAuthKeyIndex].oAuthKey = oAuthKey
        oAuthKeys[oAuthKeyIndex].expiresAt = expiresAt
    }
}

func oAuthKey(id: String) -> String? {
    var found = false
    for oAuthKeyModel in oAuthKeys {
        if oAuthKeyModel.id == id {
            found = true
            if oAuthKeyModel.expiresAt > Date().timeIntervalSince1970 {
                return oAuthKeyModel.oAuthKey
            } else {
                found = false
            }
        }
    }
    if found == false {
        if let result = oAuthSPUser(id: id) {
            guard let refreshToken = result["refresh_token"] as? String, let refreshTokenExpiresIn = result["refresh_expires_in"] as? Int, let oAuthKey = result["oauth_key"] as? String, let oAuthKeyExpiresAt = result["expires_at"] as? String else { return nil }
            guard let expiresAt = Double(oAuthKeyExpiresAt) else { return nil }
            updateRefreshToken(id: id, refreshToken: refreshToken, expiresIn: refreshTokenExpiresIn)
            updateoAuthKey(id: id, oAuthKey: oAuthKey, expiresAt: expiresAt)
            return oAuthKey
        }
    }
    return nil
}

// MARK: - RefreshToken

func updateRefreshToken(id: String, refreshToken: String, expiresIn: Int) {
    var refreshTokenIndex = -1
    for (index, element) in refreshTokens.enumerated() {
        if element.id == id {
            refreshTokenIndex = index
            break
        }
    }
    if refreshTokenIndex == -1 {
        refreshTokens.append(refreshTokenModel(id: id, refreshToken: refreshToken, expiresIn: expiresIn))
    } else {
        refreshTokens[refreshTokenIndex].refreshToken = refreshToken
        refreshTokens[refreshTokenIndex].expiresIn = expiresIn
    }
}

func refreshToken(id: String) -> String? {
    var found = false
    for refreshTokenModel in refreshTokens {
        if refreshTokenModel.id == id {
            found = true
            if refreshTokenModel.expiresIn > 0 {
                return refreshTokenModel.refreshToken
            } else {
                found = false
            }
        }
    }
    if found == false {
        if let result = getUser(id: id) {
            guard let refreshToken = result["refresh_token"] as? String else { return nil }
            updateRefreshToken(id: id, refreshToken: refreshToken, expiresIn: 0)
            return refreshToken
        }
    }
    return nil
}
