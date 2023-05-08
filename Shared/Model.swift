//
//  Model.swift
//  ChineseTime
//
//  Created by LEO Yoon-Tsaw on 9/21/21.
//

import Foundation

private let beijingTime = TimeZone(identifier: "Asia/Shanghai")!
private let utcCalendar = Calendar.utcCalendar

extension Calendar {
    static var utcCalendar: Self {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone(abbreviation: "UTC")!
        return cal
    }
    func startOfDay(for day: Date, apparent: Bool, location: CGPoint?) -> Date {
        func convertToApparent(date: Date, location: CGPoint) -> Date {
            var start = date
            let timezoneDiff = Double(timeZone.secondsFromGMT(for: start)) - location.y / 360 * 86400
            start += timezoneDiff
            start -= equationOfTime(D: fromJD2000(date: start)) / (2 * Double.pi) * 86400
            return start
        }
        let standardStartOfDay = startOfDay(for: day)
        var startToday = standardStartOfDay
        if let location = location, apparent {
            startToday = convertToApparent(date: startToday, location: location)
            if day < startToday {
                var startYesterday = self.date(byAdding: .day, value: -1, to: standardStartOfDay)!
                startYesterday = convertToApparent(date: startYesterday, location: location)
                return startYesterday
            } else {
                var startTomorrow = self.date(byAdding: .day, value: 1, to: standardStartOfDay)!
                startTomorrow = convertToApparent(date: startTomorrow, location: location)
                if day >= startTomorrow {
                    return startTomorrow
                } else {
                    return startToday
                }
            }
        } else {
            return startToday
        }
    }
}

private func getJD(yyyy: Int, mm: Int, dd: Int) -> Double {
    var m1 = mm
    var yy = yyyy
    if m1 <= 2 {
        m1 = m1 + 12
        yy = yy - 1
    }
  // Gregorian calendar
    let b = yy / 400 - yy / 100 + yy / 4
    let jd = Double(365 * yy - 679004 + b) + floor(30.6001 * Double(m1 + 1)) + Double(dd) + 2400000.5
    return jd
}

private func DeltaT_spline_y(_ y: Double) -> Double {
    func phase(x: Double) -> Double {
        let t = x - 1825
        return 0.00314115 * t * t + 284.8435805251424 * cos(0.4487989505128276 * (0.01 * t + 0.75))
    }
    if (y < -720) {
        let const: Double = 1.007739546148514
        return phase(x: y) + const
    } else if (y > 2019) {
        let const: Double = -150.263031657016
        return phase(x: y) + const
    }
    let n = [-720, -100, 400, 1000, 1150, 1300, 1500, 1600, 1650, 1720, 1800, 1810, 1820, 1830, 1840, 1850, 1855, 1860, 1865, 1870, 1875, 1880, 1885, 1890, 1895, 1900, 1905, 1910, 1915, 1920, 1925, 1930, 1935, 1940, 1945, 1950, 1953, 1956, 1959, 1962, 1965, 1968, 1971, 1974, 1977, 1980, 1983, 1986, 1989, 1992, 1995, 1998, 2001, 2004, 2007, 2010, 2013, 2016]

    var l = n.count - 1
    while l >= 0 && !(y >= Double(n[l])) {
        l -= 1
    }
    
    let year_splits = [-100, 400, 100, 1150, 1300, 1500, 1600, 1650, 1720, 1800, 1810, 1820, 1830, 1840, 1850, 1855, 1860, 1865, 1870, 1875, 1880, 1885, 1890, 1895, 1900, 1905, 1910, 1915, 1920, 1925, 1930, 1935, 1940, 1945, 1950, 1953, 1956, 1959, 1962, 1965, 1968, 1971, 1974, 1977, 1980, 1983, 1986, 1989, 1992, 1995, 1998, 2001, 2004, 2007, 2010, 2013, 2016, 2019]
    let r = (y - Double(n[l])) / Double(year_splits[l] - n[l])
    let coef1: [Double] = [20371.848, 11557.668, 6535.116, 1650.393, 1056.647, 681.149, 292.343, 109.127, 43.952, 12.068, 18.367, 15.678, 16.516, 10.804, 7.634, 9.338, 10.357, 9.04, 8.255, 2.371, -1.126, -3.21, -4.388, -3.884, -5.017, -1.977, 4.923, 11.142, 17.479, 21.617, 23.789, 24.418, 24.164, 24.426, 27.05, 28.932, 30.002, 30.76, 32.652, 33.621, 35.093, 37.956, 40.951, 44.244, 47.291, 50.361, 52.936, 54.984, 56.373, 58.453, 60.678, 62.898, 64.083, 64.553, 65.197, 66.061, 66.92, 68.109]
    let coef2: [Double] = [-9999.586, -5822.27, -5671.519, -753.21, -459.628, -421.345, -192.841, -78.697, -68.089, 2.507, -3.481, 0.021, -2.157, -6.018, -0.416, 1.642, -0.486, -0.591, -3.456, -5.593, -2.314, -1.893, 0.101, -0.531, 0.134, 5.715, 6.828, 6.33, 5.518, 3.02, 1.333, 0.052, -0.419, 1.645, 2.499, 1.127, 0.737, 1.409, 1.577, 0.868, 2.275, 3.035, 3.157, 3.199, 3.069, 2.878, 2.354, 1.577, 1.648, 2.235, 2.324, 1.804, 0.674, 0.466, 0.804, 0.839, 1.007, 1.277]
    let coef3: [Double] = [776.247, 1303.151, -298.291, 184.811, 108.771, 61.953, -6.572, 10.505, 38.333, 41.731, -1.126, 4.629, -6.806, 2.944, 2.658, 0.261, -2.389, 2.284, -5.148, 3.011, 0.269, 0.152, 1.842, -2.474, 3.138, 2.443, -1.329, 0.831, -1.643, -0.856, -0.831, -0.449, -0.022, 2.086, -1.232, 0.22, -0.61, 1.282, -1.115, 0.406, 1.002, -0.242, 0.364, -0.323, 0.193, -0.384, -0.14, -0.637, 0.708, -0.121, 0.21, -0.729, -0.402, 0.194, 0.144, -0.109, 0.277, -0.007]
    let coef4: [Double] = [409.16, -503.433, 1085.087, -25.346, -24.641, -29.414, 16.197, 3.018, -2.127, -37.939, 1.918, -3.812, 3.25, -0.096, -0.539, -0.883, 1.558, -2.477, 2.72, -0.914, -0.039, 0.563, -1.438, 1.871, -0.232, -1.257, 0.72, -0.825, 0.262, 0.008, 0.127, 0.142, 0.702, -1.106, 0.614, -0.277, 0.631, -0.799, 0.507, 0.199, -0.414, 0.202, -0.229, 0.172, -0.192, 0.081, -0.165, 0.448, -0.276, 0.11, -0.313, 0.109, 0.199, -0.017, -0.084, 0.128, -0.095, -0.139]
    return coef1[l] + r * (coef2[l] + r * (coef3[l] + r * coef4[l]))
}
// UT -> TT
private func DeltaT(T: Double) -> Double {
    let t = 36525 * T + 2451545
    if (t > 2459580.5 || t < 2441317.5) {
        return DeltaT_spline_y(t >= 2299160.5 ? (t - 2451544.5) / 365.2425 + 2000 : (t + 0.5) / 365.25 - 4712) / 86400.0
    }
    let l: [Double] = [2457754.5, 2457204.5, 2456109.5, 2454832.5, 2453736.5, 2451179.5, 2450630.5, 2450083.5, 2449534.5, 2449169.5, 2448804.5, 2448257.5, 2447892.5, 2447161.5, 2446247.5, 2445516.5, 2445151.5, 2444786.5, 2444239.5, 2443874.5, 2443509.5, 2443144.5, 2442778.5, 2442413.5, 2442048.5, 2441683.5, 2441499.5, 2441133.5]
    let n = l.count
    var DT: Double = 42.184
    for i in 0..<n {
        if (t > l[i]) {
            DT += Double(n - i - 1)
            break
        }
    }
    return DT/86400.0
}

private func mod2pi_de(x: Double) -> Double {
    return x - 2 * Double.pi * floor(0.5 * x/Double.pi + 0.5)
}

private func decode_solar_terms(y: Int, istart: Int, offset_comp: Int, solar_comp: [Int8]) -> [Date] {
    let jd0 = getJD(yyyy: y-1,mm: 12,dd: 31) - 1.0/3
    let delta_T = DeltaT(T: (jd0-2451545 + 365.25*0.5)/36525)
    let offset = 2451545 - jd0 - delta_T
    let w: [Double] = [2*Double.pi, 6.282886, 12.565772, 0.337563, 83.99505, 77.712164, 5.7533, 3.9301]
    let poly_coefs: [Double]
    let amp: [Double]
    let ph: [Double]
    if (y > 2500) {
        poly_coefs = [-10.60617210417765, 365.2421759265393, -2.701502510496315e-08, 2.303900971263569e-12]
        amp = [0.1736157870707964, 1.914572713893651, 0.0113716862045686, 0.004885711219368455, 0.0004032584498264633, 0.001736052092601642, 0.002035081600709588, 0.001360448706185977]
        ph = [-2.012792258215681, 2.824063083728992, -0.4826844382278376, 0.9488391363261893, 2.646697770061209, -0.2675341497460084, 0.9646288791219602, -1.808852094435626]
    } else if (y > 1500) {
        poly_coefs = [-10.6111079510509, 365.2421925947405, -3.888654930760874e-08, -5.434707919089998e-12]
        amp = [0.1633918030382493, 1.95409759473169, 0.01184405584067255, 0.004842563463555804, 0.0004137082581449113, 0.001732513547029885, 0.002025850272284684, 0.001363226024948773]
        ph = [-1.767045717746641, 2.832417615687159, -0.465176623256009, 0.9461667782644696, 2.713020913181211, -0.2031148059020781, 0.9980808019332812, -1.832536089597202]
    } else {
        poly_coefs = []
        amp = []
        ph = []
    }

    var sterm = [Date]()
    for i in 0..<solar_comp.count {
        let Ls = Double(y - 2000) + Double(i + istart)/24.0
        var s = poly_coefs[0] + offset + Ls*(poly_coefs[1] + Ls*(poly_coefs[2] + Ls*poly_coefs[3]))
        for j in 0..<8 {
            let ang = mod2pi_de(x: w[j] * Ls) + ph[j]
            s += amp[j] * sin(ang)
        }
        let s1 = Int((s-floor(s))*1440 + 0.5)
        let datetime = s1 + 1441 * Int(floor(s)) + Int(solar_comp[i]) - offset_comp
        let day = datetime.quotient(rhs: 1441)
        let hourminute = datetime - 1441 * day
        let hour = hourminute.quotient(rhs: 60)
        let minute = hourminute - 60 * hour
        
        let timezone = beijingTime
        let the_date = Date.from(year: y, month: 1, day: day, hour: hour, minute: minute, timezone: timezone)
        sterm.append(the_date!)
    }
    return sterm
}

private func decode_moon_phases(y: Int, offset_comp: Int, lunar_comp: [Int8], dp: Double) -> [Date] {
    let w = [2*Double.pi, 6.733776, 13.467552, 0.507989, 0.0273143, 0.507984, 20.201328, 6.225791, 7.24176, 5.32461, 12.058386, 0.901181, 5.832595, 12.56637061435917, 19.300146, 11.665189, 18.398965, 6.791174, 13.636974, 1.015968, 6.903198, 13.07437, 1.070354, 6.340578614359172]
    let poly_coefs: [Double]
    let amp: [Double]
    let ph: [Double]
    if (y > 2500) {
        poly_coefs = [5.093879710922470, 29.53058981687484, 2.670339910922144e-11, 1.807808217274283e-15]
        amp = [0.00306380948959271, 6.08567588841838, 0.3023856209133756, 0.07481389897992345, 0.0001587661348338354, 0.1740759063081489, 0.0004131985233772993, 0.005796584475300004, 0.008268929076163079, 0.003256244384807976, 0.000520983165608148, 0.003742624708965854, 1.709506053530008, 28216.70389751519, 1.598844831045378, 0.314745599206173, 6.602993931108911, 0.0003387269181720862, 0.009226112317341887, 0.00196073145843697, 0.001457643607929487, 6.467401779992282e-05, 0.0007716739483064076, 0.001378880922256705]
        ph = [-0.0001879456766404132, -2.745704167588171, -2.348884895288619, 1.420037528559222, -2.393586904955103, -0.3914194006325855, 1.183088056748942, -2.782692143601458, 0.4430565056744425, -0.4357413971405519, -3.081209195003025, 0.7945051912707899, -0.4010911170136437, 3.003035462639878e-10, 0.4040070684461441, 2.351831380989509, 2.748612213507844, 3.133002890683667, -0.6902922380876192, 0.09563473131477442, 2.056490394534053, 2.017507533465959, 2.394015964756036, -0.3466427504049927]
    } else if (y > 1500) {
        poly_coefs = [5.097475813506625, 29.53058886049267, 1.095399949433705e-10, -6.926279905270773e-16]
        amp = [0.003064332812182054, 0.8973816160666801, 0.03119866094731004, 0.07068988004978655, 0.0001583070735157395, 0.1762683983928151, 0.0004131592685474231, 0.005950873973350208, 0.008489324571543966, 0.00334306526160656, 0.00052946042568393, 0.003743585488835091, 0.2156913373736315, 44576.30467073629, 0.1050203948601217, 0.01883710371633125, 0.380047745859265, 0.0003472930592917774, 0.009225665415301823, 0.002061407071938891, 0.001454599562245767, 5.856419090840883e-05, 0.0007688706809666596, 0.001415547168551922]
        ph = [-0.0003231124735555465, 0.380955331199635, 0.762645225819612, 1.4676293538949, -2.15595770830073, -0.3633370464549665, 1.134950591549256, -2.808169363709888, 0.422381840383887, -0.4226859182049138, -3.091797336860658, 0.7563140142610324, -0.3787677293480213, 1.863828515720658e-10, 0.3794794147818532, -0.7671105159156101, -0.3850942687637987, -3.098506117162865, -0.6738173539748421, 0.09011906278589261, 2.089832317302934, 2.160228985413543, -0.6734226930504117, -0.3333652792566645]
    } else {
        poly_coefs = []
        amp = []
        ph = []
    }

    let jd0 = getJD(yyyy: y-1,mm: 12,dd: 31) - 1.0/3
    let delta_T = DeltaT(T: (jd0-2451545 + 365.25*0.5)/36525)
    let offset = 2451545 - jd0 - delta_T
    let lsyn: Double = 29.5306
    let p0 = lunar_comp[0]
    let jdL0 = 2451550.259469 + 0.5*Double(p0)*lsyn

    // Find the lunation number of the first moon phase in the year
    var Lm0 = floor((jd0 + 1 - jdL0)/lsyn)-1
    var Lm: Double = 0
    var s: Double = 0
    var s1: Int = 0
    for i in 0..<10 {
        Lm = Lm0 + 0.5*Double(p0) + Double(i)
        s = poly_coefs[0] + offset + Lm*(poly_coefs[1] + Lm*(poly_coefs[2] + Lm*poly_coefs[3]))
        for j in 0..<24 {
            let ang = mod2pi_de(x: w[j]*Lm) + ph[j]
            s += amp[j] * sin(ang)
        }
        s1 = Int((s-floor(s))*1440 + 0.5)
        s = Double(s1) + 1441*floor(s) + Double(lunar_comp[1]) - Double(offset_comp)
        if (s > 1440) {
            break
        }
    }
    Lm0 = Lm
    var mphase = [Date]()
    // Now decompress the remaining moon-phase times
    for i in 1..<lunar_comp.count {
        Lm = Lm0 + Double((i-1))*dp
        s = poly_coefs[0] + offset + Lm*(poly_coefs[1] + Lm*(poly_coefs[2] + Lm*poly_coefs[3]))
        for j in 0..<24 {
            let ang = mod2pi_de(x: w[j]*Lm) + ph[j]
            s += amp[j] * sin(ang)
        }
        s1 = Int((s-floor(s))*1440 + 0.5)
        let datetime = s1 + 1441 * Int(floor(s)) + Int(lunar_comp[i]) - offset_comp
        let day = datetime.quotient(rhs: 1441)
        let hourminute = datetime - 1441 * day
        let hour = hourminute.quotient(rhs: 60)
        let minute = hourminute - 60 * hour
        let timezone = beijingTime
        
        let the_date = Date.from(year: y, month: 1, day: day, hour: hour, minute: minute, timezone: timezone)
        mphase.append(the_date!)
    }
    return mphase
}

private func solar_terms_in_year(_ year: Int) -> [Date] {
    // year in [1900, 3000]
    return decode_solar_terms(y: year, istart: 0, offset_comp: 5, solar_comp: sunData[year - 1900])
}

private func moon_phase_in_year(_ year: Int) -> ([Date], Int8) {
    // year in [1900, 3000]
    return (decode_moon_phases(y: year, offset_comp: 5, lunar_comp: moonData[year - 1900], dp: 0.5), moonData[year - 1900][0])
}

private func fromJD2000(date: Date) -> Double {
    var dateComponents = utcCalendar.dateComponents([.year, .month, .day], from: date)
    dateComponents.hour = 12
    let noon = utcCalendar.date(from: dateComponents)!
    let j2000 = getJD(yyyy: dateComponents.year!, mm: dateComponents.month!, dd: dateComponents.day!)
    let delta_j2000 = DeltaT(T: (j2000-2451545 + 365.25*0.5)/36525)
    var offset = j2000 + delta_j2000 - 2451544.5
    offset += noon.distance(to: date) / 86400
    return offset
}

private func intraday_solar_times(chineseCalendar: ChineseCalendar, location: CGPoint) -> [Date?] {
    let calendar = chineseCalendar.calendar
    func timeOfDate(date: Date, hour: Int) -> Date {
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = hour
        let newDate = calendar.date(from: dateComponents)!
        var delta = TimeInterval(calendar.timeZone.secondsFromGMT(for: newDate))
        delta -= location.y / 360 * 86400
        return newDate + delta
    }
    
    let approximateDate = chineseCalendar.startOfDay.addingTimeInterval(43200)
    let localNoon = timeOfDate(date: approximateDate, hour: 12)
    let noonTime = localNoon - equationOfTime(D: fromJD2000(date: localNoon)) / (2 * Double.pi) * 86400
    let priorMidNight = timeOfDate(date: approximateDate, hour: 0)
    let nextMidNight = timeOfDate(date: approximateDate, hour: 24)
    let priorMidNightTime = priorMidNight - equationOfTime(D: fromJD2000(date: priorMidNight)) / (2 * Double.pi) * 86400
    let nextMidNightTime = nextMidNight - equationOfTime(D: fromJD2000(date: nextMidNight)) / (2 * Double.pi) * 86400
    
    let sunriseSunsetOffset = daytimeOffset(latitude: location.x / 180 * Double.pi, progressInYear: chineseCalendar.sunPosition(time: chineseCalendar.time) * 2 * Double.pi) / (2 * Double.pi) * 86400
    let results: [Date?]
    if sunriseSunsetOffset == Double.infinity { //Extreme day
        results = [nil, nil, noonTime, nil, nil]
    } else if sunriseSunsetOffset == -Double.infinity { //Extreme night
        results = [priorMidNightTime, nil, nil, nil, nextMidNightTime]
    } else {
        var sunriseTime = localNoon - sunriseSunsetOffset
        var sunsetTime = localNoon + sunriseSunsetOffset
        sunriseTime -= equationOfTime(D: fromJD2000(date: sunriseTime)) / (2 * Double.pi) * 86400
        sunsetTime -= equationOfTime(D: fromJD2000(date: sunsetTime)) / (2 * Double.pi) * 86400
        results = [priorMidNightTime, sunriseTime, noonTime, sunsetTime, nextMidNightTime]
    }
    return results
}

private func intraday_lunar_times(chineseCalendar: ChineseCalendar, location: CGPoint) -> [Date?] {

    func riseAndSet(meridianTime: Date, latitude: Double, light: Bool) -> ([Date?], Double) {
        let offsetMeridian = lunarTimeOffset(latitude: location.x / 180 * Double.pi, jdTime: fromJD2000(date: meridianTime), light: light)
        let moonrise = meridianTime - offsetMeridian / (2*Double.pi) * 360 / (earthSpeed - moonSpeed)
        let moonset = meridianTime + offsetMeridian / (2*Double.pi) * 360 / (earthSpeed - moonSpeed)
        if offsetMeridian == Double.infinity {
            return ([nil, meridianTime, nil], offsetMeridian)
        } else if offsetMeridian == -Double.infinity {
            return ([nil, nil, nil], offsetMeridian)
        } else {
            return ([moonrise, meridianTime, moonset], offsetMeridian)
        }
    }
    func roundHalf(_ num: Double) -> Double {
        return num - 1 - floor(num - 0.5)
    }
    
    func calDiff(time: Date) -> Double {
        let (ra, _, _) = moonEquatorPosition(D: fromJD2000(date: time))
        let dayStart = chineseCalendar.calendar.startOfDay(for: time, apparent: true, location: location)
        let nextDay = chineseCalendar.calendar.startOfDay(for: dayStart + 86400 * 1.5, apparent: true, location: location)
        return roundHalf(-chineseCalendar.sunPosition(time: time) - 1/4 - dayStart.distance(to: time) / dayStart.distance(to: nextDay) + ra / (2*Double.pi))
    }

    let longitudeDiff = calDiff(time: chineseCalendar.time)
    var timeUnderMeridianNext: Date, timeUnderMeridianPrevious: Date
    if longitudeDiff >= 0 {
        timeUnderMeridianNext = chineseCalendar.time + longitudeDiff * 360 / (earthSpeed - moonSpeed)
        timeUnderMeridianPrevious = chineseCalendar.time + (longitudeDiff - 1) * 360 / (earthSpeed - moonSpeed)
    } else {
        timeUnderMeridianPrevious = chineseCalendar.time + longitudeDiff * 360 / (earthSpeed - moonSpeed)
        timeUnderMeridianNext = chineseCalendar.time + (longitudeDiff + 1) * 360 / (earthSpeed - moonSpeed)
    }
    let beginOfToday = chineseCalendar.startOfDay
    let endOfToday = chineseCalendar.startOfNextDay
    if timeUnderMeridianPrevious.advanced(by: 43200) < beginOfToday {
        timeUnderMeridianPrevious += 360 / (earthSpeed - moonSpeed)
        timeUnderMeridianNext += 360 / (earthSpeed - moonSpeed)
    } else if timeUnderMeridianNext.advanced(by: -43200) >= endOfToday {
        timeUnderMeridianPrevious -= 360 / (earthSpeed - moonSpeed)
        timeUnderMeridianNext -= 360 / (earthSpeed - moonSpeed)
    }
    timeUnderMeridianPrevious += calDiff(time: timeUnderMeridianPrevious) * 360 / (earthSpeed - moonSpeed)
    timeUnderMeridianNext += calDiff(time: timeUnderMeridianNext) * 360 / (earthSpeed - moonSpeed)
    
    let (previousTimes, offset1) = riseAndSet(meridianTime: timeUnderMeridianPrevious, latitude: location.x, light: true)
    let (nextTimes, offset2) = riseAndSet(meridianTime: timeUnderMeridianNext, latitude: location.x, light: true)
    let midtime = timeUnderMeridianPrevious + timeUnderMeridianPrevious.distance(to: timeUnderMeridianNext) / 2
    let (midTimes, offset) = riseAndSet(meridianTime: midtime, latitude: location.x, light: false)

    var results = [previousTimes[0], previousTimes[1]]
    if let set1 = previousTimes[2], let set2 = midTimes[0] {
        results.append(set2 + set2.distance(to: set1) * (1 + (offset - offset1) / Double.pi) / 2)
    } else {
        if offset == -Double.infinity {
            results.append(nil)
        } else {
            results.append(previousTimes[2] ?? midTimes[0])
        }
    }
    if let set1 = midTimes[2], let set2 = nextTimes[0] {
        results.append(set2 + set2.distance(to: set1) * (1 + (offset2 - offset) / Double.pi) / 2)
    } else {
        if offset == -Double.infinity {
            results.append(nil)
        } else {
            results.append(nextTimes[0] ?? midTimes[2])
        }
    }
    results.append(contentsOf: [nextTimes[1], nextTimes[2]])    
    return results
}

extension Date {
    static func from(year: Int, month: Int, day: Int, hour: Int, minute: Int, timezone: TimeZone?) -> Date? {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        if let timezone = timezone {
            dateComponents.timeZone = timezone
        }
        return Calendar(identifier: .iso8601).date(from: dateComponents)
    }
}

extension Int {
    func quotient(rhs: Int) -> Int {
        if self < 0 {
            return (self - (rhs - 1)) / rhs
        } else {
            return self / rhs
        }
    }
}

extension Array {
    func slice(from: Int = 0, to: Int? = nil, step: Int = 1) -> Self {
        var sliced = Self()
        var i = from
        let limit = to ?? self.count
        while i < limit {
            sliced.append(self[i])
            i += step
        }
        return sliced
    }
}

class ChineseCalendar {
    
    static let month_chinese = ["冬月", "臘月", "正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月"]
    static let month_chinese_compact = ["㋊", "㋋", "㋀", "㋁", "㋂", "㋃", "㋄", "㋅", "㋆", "㋇", "㋈", "㋉"]
    static let day_chinese = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十" ,"十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十", "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"]
    static let day_chinese_compact = ["㏠", "㏡", "㏢", "㏣", "㏤", "㏥", "㏦", "㏧", "㏨", "㏩" ,"㏪", "㏫", "㏬", "㏭", "㏮", "㏯", "㏰", "㏱", "㏲", "㏳", "㏴", "㏵", "㏶", "㏷", "㏸", "㏹", "㏺", "㏻", "㏼", "㏽"]
    static let terrestrial_branches = ["子","丑","寅","卯","辰","巳","午","未","申","酉","戌","亥"]
    static let sub_hour_name = ["初", "正"]
    static let chinese_numbers = ["初", "一", "二", "三", "四", "五"]
    static let evenSolarTermChinese = ["冬　至", "大　寒", "雨　水", "春　分", "穀　雨", "小　滿", "夏　至", "大　暑", "處　暑", "秋　分", "霜　降", "小　雪"]
    static let oddSolarTermChinese = ["小　寒", "立　春", "驚　蟄", "清　明", "立　夏", "芒　種", "小　暑", "立　秋", "白　露", "寒　露", "立　冬", "大　雪"]
    static let leapLabel = "閏"
    static let alternativeMonthName = ["閏正月": "閏一月"]
    static var globalMonth = false
    static var apparentTime = false
    
    private var _time: Date
    private var _calendar: Calendar
    private var _solarTerms: [Date]
    private let _year_length: Double
    private let _year: Int
    private let _evenSolarTerms: [Date]
    private let _oddSolarTerms: [Date]
    private let _moonEclipses: [Date]
    private let _fullMoons: [Date]
    private let _monthNames: [String]
    private let _monthNamesFull: [String]
    private var _month: Int
    private var _precise_month: Int
    private var _day: Int
    private var _location: CGPoint?
    private var _sunTimes: [Date?] = []
    private var _moonTimes: [Date?] = []
    private var _startHour = Date()
    private var _endHour = Date()
    private var _hourNames: [String]
    private var _time_string: String
    private let _compact: Bool
    
    struct CelestialEvent {
        var eclipse = [Double]()
        var fullMoon = [Double]()
        var oddSolarTerm = [Double]()
        var evenSolarTerm = [Double]()
    }
    struct DailyEvent {
        var solar = [Double?]()
        var lunar = [Double?]()
    }
    struct Ticks {
        struct TickName {
            var position: Double = 0.0
            var name: String = ""
            var active: Bool = false
        }
        var majorTicks = [Double]()
        var majorTickNames = [TickName]()
        var minorTicks = [Double]()
    }
    
    init(time: Date, timezone: TimeZone, location: CGPoint?, compact: Bool = false) {
        self._time = time
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = timezone
        self._calendar = calendar
        var year = calendar.component(.year, from: time)
        var solar_terms = solar_terms_in_year(year + 1)
        if solar_terms[0] <= time {
            year += 1
            solar_terms += solar_terms_in_year(year + 1)[0...4]
        } else {
            var solar_terms_current_year = solar_terms_in_year(year)
            solar_terms_current_year += solar_terms[0...4]
            solar_terms = solar_terms_current_year
        }
        let solar_terms_previous_year = solar_terms_in_year(year - 1)
        
        let (moon_phase_previous_year, first_event) = moon_phase_in_year(year - 1)
        var (moon_phase, _) = moon_phase_in_year(year)
        let (moon_phase_next_year, _) = moon_phase_in_year(year + 1)
        moon_phase = moon_phase_previous_year + moon_phase + moon_phase_next_year
        var eclipse = moon_phase.slice(from: Int(first_event), step: 2)
        var fullMoon = moon_phase.slice(from: Int(1-first_event), step: 2)
        var start: Int? = nil, end: Int? = nil
        for i in 0..<eclipse.count {
            let eclipseDate: Date
            if Self.globalMonth {
                eclipseDate = eclipse[i]
            } else {
                eclipseDate = calendar.startOfDay(for: eclipse[i], apparent: Self.apparentTime, location: location)
            }
            if (start == nil) && (eclipseDate >= solar_terms[0]) {
                start = i-1
            }
            if (end == nil) && (eclipseDate > solar_terms[24]) {
                end = i
            }
        }
        eclipse = eclipse.slice(from: start!, to: end!+2)
        fullMoon = fullMoon.filter { $0 < eclipse.last! && $0 > eclipse[0] }
        let evenSolarTerms = solar_terms.slice(step: 2)
        
        var i = 0
        var j = 0
        var count = 0
        var solatice_in_month = [Int]()
        var monthCount = Set<Date>()
        while (i+1 < eclipse.count) && (j < evenSolarTerms.count) {
            let thisEclipse: Date
            let nextEclipse: Date
            if Self.globalMonth {
                thisEclipse = eclipse[i]
                nextEclipse = eclipse[i+1]
            } else {
                thisEclipse = calendar.startOfDay(for: eclipse[i], apparent: Self.apparentTime, location: location)
                nextEclipse = calendar.startOfDay(for: eclipse[i+1], apparent: Self.apparentTime, location: location)
            }
            if ((thisEclipse <= evenSolarTerms[j]) && (nextEclipse > evenSolarTerms[j])) {
                count += 1
                j += 1
            } else {
                solatice_in_month.append(count)
                count = 0
                i += 1
            }
            if thisEclipse >= solar_terms[0] && thisEclipse < solar_terms[24] {
                monthCount.insert(thisEclipse)
            }
        }
        var months_compact = [String]()
        var months = [String]()
        
        if monthCount.count == 12 {
            months_compact = (Self.month_chinese_compact + Self.month_chinese_compact).slice(to: eclipse.count)
            months = (Self.month_chinese + Self.month_chinese).slice(to: eclipse.count)
        } else if monthCount.count > 12 {
            var leap = 0
            var leapLabel = ""
            for i in 0..<solatice_in_month.count {
                if ((solatice_in_month[i] == 0) && leap == 0) {
                    leap = 1
                    leapLabel = Self.leapLabel
                } else {
                    leapLabel = ""
                }
                var month_name = leapLabel + Self.month_chinese[(i - leap) % 12]
                let month_name_compact = leapLabel + Self.month_chinese_compact[(i - leap) % 12]
                if let alter = Self.alternativeMonthName[month_name] {
                    month_name = alter
                }
                months.append(month_name)
                months_compact.append(month_name_compact)
            }
        }
        
        self._solarTerms = Array(solar_terms[0...24])
        self._year_length = solar_terms[0].distance(to: solar_terms[24])
        var evenSolar = solar_terms.slice(from: 0, step: 2)
        evenSolar.insert(solar_terms_previous_year[solar_terms_previous_year.count-2], at: 0)
        self._evenSolarTerms = evenSolar
        var oddSolar = solar_terms.slice(from: 1, step: 2)
        oddSolar.insert(solar_terms_previous_year[solar_terms_previous_year.count-1], at: 0)
        self._oddSolarTerms = oddSolar
        self._moonEclipses = eclipse
        self._monthNames = compact ? months_compact : months
        self._monthNamesFull = months
        self._fullMoons = fullMoon
        self._year = year
        self._hourNames = []
        self._location = location
        self._time_string = ""
        self._month = -1
        self._day = -1
        self._precise_month = -1
        self._compact = compact
    }
    
    func updateDate() {
        var i = 0
        while i < _moonEclipses.count - 1 {
            let startOfEclipse = _calendar.startOfDay(for: _moonEclipses[i], apparent: apparentTime, location: _location)
            let startOfDate = _calendar.startOfDay(for: _time, apparent: apparentTime, location: _location)
            if startOfEclipse > startOfDate {
                break
            }
            i += 1
        }
        var j = 0
        while j < _moonEclipses.count - 1 {
            if _moonEclipses[j] > _time {
                break
            }
            j += 1
        }
        let previousEclipse = _calendar.startOfDay(for: _moonEclipses[i-1], apparent: apparentTime, location: _location)
        let startOfDate = _calendar.startOfDay(for: _time, apparent: apparentTime, location: _location)
        let date_diff = Int(round(previousEclipse.distance(to: startOfDate) / 86400))
        _month = i-1
        _precise_month = j-1
        _day = date_diff
    }
    
    // If return true, update succeed, otherwise fail
    func update(time: Date, timezone: TimeZone, location: CGPoint?) -> Bool {
        if timezone != self._calendar.timeZone {
            return false
        }
        self._time = time
        self._calendar.timeZone = timezone
        self._location = location
        let year = _calendar.component(.year, from: time)
        if ((year == _year) && (_solarTerms[24] > time)) || ((year == _year - 1) && (_solarTerms[0] <= time)) {
            return true
        } else {
            return false
        }
    }

    var apparentTime: Bool {
        Self.apparentTime && _location != nil
    }
    var dateString: String {
        let chinese_month = _monthNamesFull[_month]
        let chinese_day = Self.day_chinese[_day]
        if chinese_day.count > 1 {
            return "\(chinese_month)\(chinese_day)"
        } else {
            return "\(chinese_month)\(chinese_day)日"
        }
    }
    var timeString: String {
        _time_string
    }
    var calendar: Calendar {
        return _calendar
    }
    var evenSolarTerms: [Double] {
        var evenSolarTermsPositions = _evenSolarTerms.map { _solarTerms[0].distance(to: $0) / _year_length as Double }
        evenSolarTermsPositions = evenSolarTermsPositions.filter { ($0 < 1) && ($0 > 0) }
        return [0] + evenSolarTermsPositions
    }
    var oddSolarTerms: [Double] {
        var oddSolarTermsPositions = _oddSolarTerms.map { _solarTerms[0].distance(to: $0) / _year_length as Double }
        oddSolarTermsPositions = oddSolarTermsPositions.filter { ($0 < 1) && ($0 > 0) }
        return oddSolarTermsPositions
    }
    var monthTicks: Ticks {
        var ticks = Ticks()
        var monthDivides: [Double]
        if Self.globalMonth {
            monthDivides = _moonEclipses.map { _solarTerms[0].distance(to: $0) / _year_length }
        } else {
            monthDivides = _moonEclipses.map { _solarTerms[0].distance(to: _calendar.startOfDay(for: $0, apparent: Self.apparentTime, location: _location)) / _year_length }
        }
        monthDivides = monthDivides.filter { $0 > 0 && $0 < 1 }
        var previousMonthDivide: Double = 0.0
        var monthNames = [Ticks.TickName]()
        let minMonthLength: Double = (_compact ? 0.009 : 0.006)
        for i in 0..<monthDivides.count {
            let position = (monthDivides[i] + previousMonthDivide) / 2
            if position - previousMonthDivide > minMonthLength * Double(_monthNames[i].count) {
                monthNames.append(Ticks.TickName(
                    position: position,
                    name: _monthNames[i],
                    active: previousMonthDivide <= currentDayInYear
                ))
            }
            previousMonthDivide = monthDivides[i]
        }
        let position = (1 + previousMonthDivide) / 2
        if position - previousMonthDivide > minMonthLength * Double(_monthNames[(monthDivides.count) % _monthNames.count].count) {
            monthNames.append(Ticks.TickName(
                position: position,
                name: _monthNames[(monthDivides.count) % _monthNames.count],
                active: previousMonthDivide <= currentDayInYear
            ))
        }

        ticks.majorTicks = [0] + monthDivides
        ticks.majorTickNames = monthNames
        ticks.minorTicks = _fullMoons.map { _solarTerms[0].distance(to: $0) / _year_length }.filter { ($0 < 1) && ($0 > 0) }
        return ticks
    }

    var dayTicks: Ticks {
        var ticks = Ticks()
        
        let monthStart: Date
        let monthEnd: Date
        var date: Date
        if Self.globalMonth {
            monthStart = _moonEclipses[_precise_month]
            monthEnd = _moonEclipses[_precise_month+1]
            date = _calendar.startOfDay(for: monthStart, apparent: Self.apparentTime, location: _location)
        } else {
            monthStart = _calendar.startOfDay(for: _moonEclipses[_month], apparent: Self.apparentTime, location: _location)
            monthEnd = _calendar.startOfDay(for: _moonEclipses[_month+1], apparent: Self.apparentTime, location: _location)
            date = monthStart
        }
        
        var dayDivides = [Date]()
        while date < monthEnd {
            if apparentTime {
                date += 86400 * 1.5
                date = _calendar.startOfDay(for: date, apparent: Self.apparentTime, location: _location)
            } else {
                date = _calendar.date(byAdding: .day, value: 1, to: date)!
            }
            dayDivides.append(date)
        }
        let majorTicks: [Double] = dayDivides.map { monthStart.distance(to: $0) / monthStart.distance(to: monthEnd) }.filter { 0 < $0 && $0 < 1 }
        
        let allDayNames: [String]
        if _compact {
            allDayNames = Self.day_chinese_compact.slice(to: monthLengthInWholeDays) + [Self.day_chinese_compact[0]]
        } else {
            allDayNames = Self.day_chinese.slice(to: monthLengthInWholeDays) + [Self.day_chinese[0]]
        }

        var dayNames = [Ticks.TickName]()
        var previousDayDivide: Double = 0.0
        let minDayLength = (_compact ? 0.009 : 0.006)
        for i in 0..<majorTicks.count {
            let position = (majorTicks[i] + previousDayDivide) / 2
            if position - previousDayDivide > minDayLength * Double(allDayNames[i].count) {
                dayNames.append(Ticks.TickName(
                    position: position,
                    name: allDayNames[i],
                    active: previousDayDivide <= currentDayInMonth
                ))
            }
            previousDayDivide = majorTicks[i]
        }
        let position = (1 + previousDayDivide) / 2
        if position - previousDayDivide > minDayLength * Double(allDayNames[majorTicks.count].count) {
            dayNames.append(Ticks.TickName(
                position: position,
                name: allDayNames[majorTicks.count],
                active: previousDayDivide <= currentDayInMonth
            ))
        }
        ticks.majorTicks = [0] + majorTicks
        ticks.majorTickNames = dayNames
        return ticks
    }
    var hourTicks: Ticks {
        var ticks = Ticks()
        var hourDivides = [Double]()
        let startOfDay = startOfDay
        let startOfNextDay = startOfNextDay
        var tempStartHour: Date? = nil
        var tempEndHour: Date? = nil
        var hour = startOfDay
        _hourNames = []
        while hour < startOfNextDay - 1 {
            hourDivides.append(startOfDay.distance(to: hour) / startOfDay.distance(to: startOfNextDay))
            let hourIndex: Int
            if apparentTime {
                hourIndex = Int(round(startOfDay.distance(to: hour) / startOfDay.distance(to: startOfNextDay) * 24))
            } else {
                hourIndex = _calendar.component(.hour, from: hour)
            }
            _hourNames.append(hourIndex % 2 == 0 ? ChineseCalendar.terrestrial_branches[(hourIndex/2)%12] : "")
            if hourIndex % 2 == 1 && hour <= _time {
                tempStartHour = hour
            }
            if hourIndex % 2 == 1 && hour > _time && tempEndHour == nil {
                tempEndHour = hour
            }
            if apparentTime {
                hour += startOfDay.distance(to: startOfNextDay) / 24
            } else {
                hour = _calendar.date(byAdding: .hour, value: 1, to: hour)!
            }
        }
        if tempStartHour == nil {
            if apparentTime {
                tempStartHour = startOfDay - startOfDay.distance(to: startOfNextDay) / 24
            } else {
                hour = _calendar.date(byAdding: .hour, value: -1, to: startOfDay)!
                while _calendar.component(.hour, from: hour) % 2 == 0 {
                    hour = _calendar.date(byAdding: .hour, value: -1, to: hour)!
                }
                tempStartHour = hour
            }
        }
        if tempEndHour == nil {
            if apparentTime {
                tempEndHour = startOfNextDay + startOfDay.distance(to: startOfNextDay) / 24
            } else {
                hour = _calendar.date(byAdding: .hour, value: 1, to: startOfNextDay)!
                while _calendar.component(.hour, from: hour) % 2 == 0 {
                    hour = _calendar.date(byAdding: .hour, value: 1, to: hour)!
                }
                tempEndHour = hour
            }
        }
        _startHour = tempStartHour!
        _endHour = tempEndHour!
        
        var quarterTick = [Double]()
        var quarter: Double = 0.0
        while quarter < 1.0 {
            quarterTick.append(quarter)
            quarter += 864 / startOfDay.distance(to: startOfNextDay)
        }
        quarterTick = Array(Set(quarterTick).subtracting(hourDivides)).sorted()
        var hourNames = [Ticks.TickName]()
        var hourStart: Double = 0.0
        for i in 0..<hourDivides.count {
            if !_hourNames[i].isEmpty {
                hourNames.append(Ticks.TickName(
                    position: hourDivides[i],
                    name: _hourNames[i],
                    active: hourStart <= currentHourInDay
                ))
            } else {
                hourStart = hourDivides[i]
            }
        }
        ticks.majorTicks = hourDivides
        ticks.majorTickNames = hourNames
        ticks.minorTicks = quarterTick
        return ticks
    }
    var subhourTicks: Ticks {
        var ticks = Ticks()
        var subHourTicks = Set<Double>()
        var majorTickNames = Array<String>()
        _time_string = ""
        var tickTime = startHour
        var currentSmallHour = tickTime
        while tickTime < endHour - 1 {
            subHourTicks.insert(startHour.distance(to: tickTime) / startHour.distance(to: endHour))
            let hourOrder: Int
            if apparentTime {
                hourOrder = Int(round(startOfDay.distance(to: tickTime) / startOfDay.distance(to: startOfNextDay) * 24))+1
            } else {
                hourOrder = _calendar.component(.hour, from: tickTime)+1
            }
            majorTickNames.append(Self.terrestrial_branches[(hourOrder/2)%12] + Self.sub_hour_name[hourOrder%2])
            if tickTime <= _time {
                _time_string = majorTickNames.last!
                currentSmallHour = tickTime
            }
            if apparentTime {
                tickTime += startOfDay.distance(to: startOfNextDay) / 24
            } else {
                tickTime = _calendar.date(byAdding: .hour, value: 1, to: tickTime)!
            }
        }
        let majorTicks = subHourTicks
        var majorTickCount = 0
        tickTime = startOfDay - 864 * 6
        var currentSubhour = currentSmallHour
        while tickTime < endHour {
            if tickTime > startHour {
                subHourTicks.insert(startHour.distance(to: tickTime) / startHour.distance(to: endHour))
            }
            if tickTime > currentSmallHour && time >= tickTime {
                currentSubhour = tickTime
                majorTickCount += 1
            }
            tickTime += 864
        }
        _time_string += Self.chinese_numbers[majorTickCount] + "刻"
        let minimumSubhourLength = _compact ? 0.045 : 0.03
        var subHourNames = [Ticks.TickName]()
        var count = 1
        var j = 0
        let subHourTick = Array(subHourTicks).sorted()
        for i in 0..<subHourTick.count {
            if majorTicks.contains(subHourTick[i]) {
                subHourNames.append(Ticks.TickName(
                    position: subHourTick[i],
                    name: majorTickNames[j],
                    active: subHourTick[i] <= subhourInHour
                ))
                j += 1
                count = 1
            } else {
                if min((subHourTick[i] - subHourTick[(i-1)%subHourTick.count]) % 1.0, (subHourTick[(i+1)%subHourTick.count] - subHourTick[i]) % 1.0) > minimumSubhourLength {
                    subHourNames.append(Ticks.TickName(
                        position: subHourTick[i],
                        name: Self.chinese_numbers[count],
                        active: subHourTick[i] <= subhourInHour
                    ))
                }
                count += 1
            }
        }
        
        var subQuarterTicks = Set<Double>()
        var minorTickCount = 0
        tickTime = startOfDay - 864 * 6
        while tickTime < endHour {
            if tickTime > startHour {
                subQuarterTicks.insert(startHour.distance(to: tickTime) / startHour.distance(to: endHour))
            }
            if tickTime > currentSubhour && time >= tickTime {
                minorTickCount += 1
            }
            tickTime += 144
        }
        if minorTickCount > 0 {
            _time_string += Self.chinese_numbers[minorTickCount]
        }
        subQuarterTicks = subQuarterTicks.subtracting(subHourTicks)
        let subQuarterTick = Array(subQuarterTicks).sorted()
        
        ticks.majorTicks = subHourTick
        ticks.majorTickNames = subHourNames
        ticks.minorTicks = subQuarterTick
        return ticks
    }
    var location: CGPoint? {
        get {
            _location
        } set {
            _location = newValue
        }
    }
    var timezone: Int {
        _calendar.timeZone.secondsFromGMT(for: _time)
    }
    var year: Int {
        _year
    }
    var month: Int {
        _month
    }
    var preciseMonth: Int {
        Self.globalMonth ? _precise_month : _month
    }
    var day: Int {
        _day + 1
    }
    var time: Date {
        _time
    }
    var monthLengthInWholeDays: Int {
        let month = Self.globalMonth ? _precise_month : _month
        let monthStartDate = _calendar.startOfDay(for: _moonEclipses[month], apparent: Self.apparentTime, location: _location)
        let monthEndDate = _calendar.startOfDay(for: _moonEclipses[month+1], apparent: Self.apparentTime, location: _location)
        return Int(round(monthStartDate.distance(to: monthEndDate) / 86400))
    }
    var startHour: Date {
        _startHour
    }
    var endHour: Date {
        _endHour
    }
    func sunPosition(time: Date) -> Double {
        func interpolate(f1: Double, f2: Double, f3: Double, y: Double) -> Double {
            let a = f2 - f1
            let b = f3 - f2 - a
            let ba = b - 2*a
            return (ba + sqrt(pow(ba,2) + 8*b*(y-f1))) / (4*b)
        }
        var i = 0
        while (i+1 < _solarTerms.count) && (time > _solarTerms[i+1]) {
            i += 1
        }
        if i <= _solarTerms.count / 2 {
            return (Double(i) + interpolate(f1: 0, f2: _solarTerms[i].distance(to: _solarTerms[i+1]), f3: _solarTerms[i].distance(to: _solarTerms[i+2]), y: _solarTerms[i].distance(to: time)) * 2) / 24
        } else {
            return (Double(i) + (interpolate(f1: 0, f2: _solarTerms[i-1].distance(to: _solarTerms[i]), f3: _solarTerms[i-1].distance(to: _solarTerms[i+1]), y: _solarTerms[i-1].distance(to: time)) - 0.5) * 2) / 24
        }
    }
    var currentDayInYear: Double {
        _solarTerms[0].distance(to: _time) / _year_length
    }
    var currentDayInMonth: Double {
        if Self.globalMonth {
            let monthLength = _moonEclipses[_precise_month].distance(to: _moonEclipses[_precise_month+1])
            return _moonEclipses[_precise_month].distance(to: _time) / monthLength
        } else {
            let monthStart = calendar.startOfDay(for: _moonEclipses[_month], apparent: Self.apparentTime, location: _location)
            let monthEnd = calendar.startOfDay(for: _moonEclipses[_month+1], apparent: Self.apparentTime, location: _location)
            return monthStart.distance(to: _time) / monthStart.distance(to: monthEnd)
        }
    }
    var currentHourInDay: Double {
        startOfDay.distance(to: _time) / startOfDay.distance(to: startOfNextDay)
    }
    var subhourInHour: Double {
        startHour.distance(to: _time) / startHour.distance(to: endHour)
    }
    var startOfDay: Date {
        _calendar.startOfDay(for: _time, apparent: Self.apparentTime, location: _location)
    }
    var startOfNextDay: Date {
        let nextDay = startOfDay + 86400 * 1.5
        return _calendar.startOfDay(for: nextDay, apparent: Self.apparentTime, location: _location)
    }
    var planetPosition: [Double] {
        var planetPosition = planetPos(T: fromJD2000(date: _time) / 36525)
        let moonPosition = moonElipticPosition(D: fromJD2000(date: _time))
        planetPosition.append(moonPosition)
        return planetPosition.map { ($0 / Double.pi / 2 + 0.25) % 1.0 }
    }
    var eventInMonth: CelestialEvent {
        let monthStart: Date
        let monthLength: Double
        if Self.globalMonth {
            monthStart = _moonEclipses[_precise_month]
            monthLength = _moonEclipses[_precise_month].distance(to: _moonEclipses[_precise_month+1])
        } else {
            monthStart = _calendar.startOfDay(for: _moonEclipses[_month], apparent: Self.apparentTime, location: _location)
            let monthEnd = _calendar.startOfDay(for: _moonEclipses[_month+1], apparent: Self.apparentTime, location: _location)
            monthLength = monthStart.distance(to: monthEnd)
        }
        var event = CelestialEvent()
        if !Self.globalMonth {
            event.eclipse = _moonEclipses.map { date in
                monthStart.distance(to: date) / monthLength
            }.filter { 0 <= $0 && 1 > $0 }
        }
        event.fullMoon = _fullMoons.map { date in
            monthStart.distance(to: date) / monthLength
        }.filter { 0 <= $0 && 1 > $0 }
        event.evenSolarTerm = _evenSolarTerms.map { date in
            monthStart.distance(to: date) / monthLength
        }.filter { 0 <= $0 && 1 > $0 }
        event.oddSolarTerm = _oddSolarTerms.map { date in
            monthStart.distance(to: date) / monthLength
        }.filter { 0 <= $0 && 1 > $0 }
        return event
    }
    var eventInDay: CelestialEvent {
        let startOfDay = startOfDay
        let lengthOfDay = startOfDay.distance(to: startOfNextDay)
        var event = CelestialEvent()
        event.eclipse = _moonEclipses.map { date in
            startOfDay.distance(to: date) / lengthOfDay
        }.filter { 0 <= $0 && $0 < 1 }
        event.fullMoon = _fullMoons.map { date in
            startOfDay.distance(to: date) / lengthOfDay
        }.filter { 0 <= $0 && $0 < 1 }
        event.evenSolarTerm = _evenSolarTerms.map { date in
            startOfDay.distance(to: date) / lengthOfDay
        }.filter { 0 <= $0 && $0 < 1 }
        event.oddSolarTerm = _oddSolarTerms.map { date in
            startOfDay.distance(to: date) / lengthOfDay
        }.filter { 0 <= $0 && $0 < 1 }
        return event
    }
    var eventInHour: CelestialEvent {
        var event = CelestialEvent()
        let hourLength = startHour.distance(to: endHour)
        event.eclipse = _moonEclipses.map { date in
            startHour.distance(to: date) / hourLength
        }.filter { 0 <= $0 && $0 < 1 }
        event.fullMoon = _fullMoons.map { date in
            startHour.distance(to: date) / hourLength
        }.filter { 0 <= $0 && $0 < 1 }
        event.evenSolarTerm = _evenSolarTerms.map { date in
            startHour.distance(to: date) / hourLength
        }.filter { 0 <= $0 && $0 < 1 }
        event.oddSolarTerm = _oddSolarTerms.map { date in
            startHour.distance(to: date) / hourLength
        }.filter { 0 <= $0 && $0 < 1 }
        return event
    }
    var sunMoonPositions: DailyEvent {
        var dailyEvent = DailyEvent()
        if let location = _location {
            _sunTimes = intraday_solar_times(chineseCalendar: self, location: location)
            _moonTimes = intraday_lunar_times(chineseCalendar: self, location: location)
            let startOfDay = startOfDay
            let startOfNextDay = startOfNextDay
            let lengthOfDay = startOfDay.distance(to: startOfNextDay)
            func dayEventMapping(date: Date?) -> Double? {
                if let date = date, date >= startOfDay && date < startOfNextDay {
                    return startOfDay.distance(to: date) / lengthOfDay
                } else {
                    return nil
                }
            }
            dailyEvent.solar = _sunTimes.map(dayEventMapping)
            dailyEvent.lunar = _moonTimes.map(dayEventMapping)
            if apparentTime {
                dailyEvent.solar[0] = nil
                dailyEvent.solar[2] = nil
                dailyEvent.solar[dailyEvent.solar.count-1] = nil
            }
        }
        return dailyEvent
    }
    var sunMoonSubhourPositions: DailyEvent {
        var dailyEvent = DailyEvent()
        func hourEventMapping(date: Date?) -> Double? {
            if let date = date, date >= startHour && date < endHour {
                return startHour.distance(to: date) / startHour.distance(to: endHour)
            } else {
                return nil
            }
        }
        if let location = _location, _sunTimes.count == 0 || _moonTimes.count == 0 {
            _sunTimes = intraday_solar_times(chineseCalendar: self, location: location)
            _moonTimes = intraday_lunar_times(chineseCalendar: self, location: location)
        }
        dailyEvent.solar = _sunTimes.map(hourEventMapping)
        dailyEvent.lunar = _moonTimes.map(hourEventMapping)
        if apparentTime {
            dailyEvent.solar[0] = nil
            dailyEvent.solar[2] = nil
            dailyEvent.solar[dailyEvent.solar.count-1] = nil
        }
        return dailyEvent
    }
}
