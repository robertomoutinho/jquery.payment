$.payment = {}
$.payment.fn = {}
$.fn.payment = (method, args...) ->
  $.payment.fn[method].apply(this, args)

# Utils

defaultFormat = /(\d{1,4})/g

$.payment.cards = cards = [
  # Debit cards must come first, since they have more
  # specific patterns than their credit-card equivalents.
  {
	type: 'elo'
	pattern: /^(401178)|(401179)|(431274)|(438935)|(457393)|(457631)|(457632)|(504175)|(506707)|(506708)|(506715)|(506717)|(506718)|(506719)|(506720)|(506721)|(506724)|(506725)|(506726)|(506727)|(506728)|(506729)|(506730)|(506731)|(506732)|(506733)|(506739)|(506740)|(506741)|(506742)|(506743)|(506744)|(506745)|(506746)|(506747)|(506748)|(506750)|(506751)|(506752)|(506753)|(506774)|(506775)|(506776)|(506777)|(506778)|(509066)|(509067)|(509068)|(509069)|(509070)|(509071)|(509072)|(636297)|(636368)|(\b50900[0-9]\b)|(\b5090(1[3-9]|2[0-9])\b)|(\b5090(3[1-9]|[45][0-9]|6[0-4])\b)|(\b509(0(7[4-9]|[89][0-9])|[1-7][0-9]{2}|80[0-7])\b)/,
	format: defaultFormat
	length: [16]
	cvcLength: [3]
	luhn: true
  }
  {
	type: 'hipercard'
	pattern: /^(606282)|(3841)/
	format: defaultFormat
	length: [16]
	cvcLength: [3]
	luhn: true
  }
  {
    type: 'visa'
    pattern: /^4/
    format: defaultFormat
    length: [16]
    cvcLength: [3]
    luhn: true
  }
  {
    type: 'mastercard'
    pattern: /^5[0-5]/
    format: defaultFormat
    length: [16]
    cvcLength: [3]
    luhn: true
  }
  {
    type: 'amex'
    pattern: /^3[47]/
    format: /(\d{1,4})(\d{1,6})?(\d{1,5})?/
    length: [15]
    cvcLength: [4]
    luhn: true
  }
  {
    type: 'dinersclub'
    pattern: /^3[0689]/
    format: /(\d{1,4})(\d{1,6})?(\d{1,4})?/
    length: [14]
    cvcLength: [3]
    luhn: true
  }
]

cardFromNumber = (num) ->
  num = (num + '').replace(/\D/g, '')
  return card for card in cards when card.pattern.test(num)

cardFromType = (type) ->
  return card for card in cards when card.type is type

luhnCheck = (num) ->
  odd = true
  sum = 0

  digits = (num + '').split('').reverse()

  for digit in digits
    digit = parseInt(digit, 10)
    digit *= 2 if (odd = !odd)
    digit -= 9 if digit > 9
    sum += digit

  sum % 10 == 0

hasTextSelected = ($target) ->
  # If some text is selected
  return true if $target.prop('selectionStart')? and
    $target.prop('selectionStart') isnt $target.prop('selectionEnd')

  # If some text is selected in IE
  if document?.selection?.createRange?
    return true if document.selection.createRange().text

  false

# Private

# Format Numeric

reFormatNumeric = (e) ->
  setTimeout ->
    $target = $(e.currentTarget)
    value   = $target.val()
    value   = value.replace(/\D/g, '')
    $target.val(value)

# Format Card Number

reFormatCardNumber = (e) ->
  setTimeout ->
    $target = $(e.currentTarget)
    value   = $target.val()
    value   = $.payment.formatCardNumber(value)
    $target.val(value)

formatCardNumber = (e) ->
  # Only format if input is a number
  digit = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  $target = $(e.currentTarget)
  value   = $target.val()
  card    = cardFromNumber(value + digit)
  length  = (value.replace(/\D/g, '') + digit).length

  upperLength = 16
  upperLength = card.length[card.length.length - 1] if card
  return if length >= upperLength

  # Return if focus isn't at the end of the text
  return if $target.prop('selectionStart')? and
    $target.prop('selectionStart') isnt value.length

  if card && card.type is 'amex'
    # AMEX cards are formatted differently
    re = /^(\d{4}|\d{4}\s\d{6})$/
  else
    re = /(?:^|\s)(\d{4})$/

  # If '4242' + 4
  if re.test(value)
    e.preventDefault()
    setTimeout -> $target.val(value + ' ' + digit)

  # If '424' + 2
  else if re.test(value + digit)
    e.preventDefault()
    setTimeout -> $target.val(value + digit + ' ')

formatBackCardNumber = (e) ->
  $target = $(e.currentTarget)
  value   = $target.val()

  # Return unless backspacing
  return unless e.which is 8

  # Return if focus isn't at the end of the text
  return if $target.prop('selectionStart')? and
    $target.prop('selectionStart') isnt value.length

  # Remove the digit + trailing space
  if /\d\s$/.test(value)
    e.preventDefault()
    setTimeout -> $target.val(value.replace(/\d\s$/, ''))
  # Remove digit if ends in space + digit
  else if /\s\d?$/.test(value)
    e.preventDefault()
    setTimeout -> $target.val(value.replace(/\d$/, ''))

# Format Expiry

reFormatExpiry = (e) ->
  setTimeout ->
    $target = $(e.currentTarget)
    value   = $target.val()
    value   = $.payment.formatExpiry(value)
    $target.val(value)

formatExpiry = (e) ->
  # Only format if input is a number
  digit = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  $target = $(e.currentTarget)
  val     = $target.val() + digit

  if /^\d$/.test(val) and val not in ['0', '1']
    e.preventDefault()
    setTimeout -> $target.val("0#{val} / ")

  else if /^\d\d$/.test(val)
    e.preventDefault()
    setTimeout -> $target.val("#{val} / ")

formatForwardExpiry = (e) ->
  digit = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  $target = $(e.currentTarget)
  val     = $target.val()

  if /^\d\d$/.test(val)
    $target.val("#{val} / ")

formatForwardSlashAndSpace = (e) ->
  which = String.fromCharCode(e.which)
  return unless which is '/' or which is ' '

  $target = $(e.currentTarget)
  val     = $target.val()

  if /^\d$/.test(val) and val isnt '0'
    $target.val("0#{val} / ")

formatBackExpiry = (e) ->
  $target = $(e.currentTarget)
  value   = $target.val()

  # Return unless backspacing
  return unless e.which is 8

  # Return if focus isn't at the end of the text
  return if $target.prop('selectionStart')? and
    $target.prop('selectionStart') isnt value.length

  # Remove the trailing space + last digit
  if /\d\s\/\s$/.test(value)
    e.preventDefault()
    setTimeout -> $target.val(value.replace(/\d\s\/\s$/, ''))

# Format CVC

reFormatCVC = (e) ->
  setTimeout ->
    $target = $(e.currentTarget)
    value   = $target.val()
    value   = value.replace(/\D/g, '')[0...4]
    $target.val(value)

# Restrictions

restrictNumeric = (e) ->
  # Key event is for a browser shortcut
  return true if e.metaKey or e.ctrlKey

  # If keycode is a space
  return false if e.which is 32

  # If keycode is a special char (WebKit)
  return true if e.which is 0

  # If char is a special char (Firefox)
  return true if e.which < 33

  input = String.fromCharCode(e.which)

  # Char is a number or a space
  !!/[\d\s]/.test(input)

restrictCardNumber = (e) ->
  $target = $(e.currentTarget)
  digit   = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  return if hasTextSelected($target)

  # Restrict number of digits
  value = ($target.val() + digit).replace(/\D/g, '')
  card  = cardFromNumber(value)

  if card
    value.length <= card.length[card.length.length - 1]
  else
    # All other cards are 16 digits long
    value.length <= 16

restrictExpiry = (e) ->
  $target = $(e.currentTarget)
  digit   = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  return if hasTextSelected($target)

  value = $target.val() + digit
  value = value.replace(/\D/g, '')

  return false if value.length > 6

restrictCVC = (e) ->
  $target = $(e.currentTarget)
  digit   = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  return if hasTextSelected($target)

  val     = $target.val() + digit
  val.length <= 4

setCardType = (e) ->
  $target  = $(e.currentTarget)
  val      = $target.val()
  cardType = $.payment.cardType(val) or 'unknown'

  unless $target.hasClass(cardType)
    allTypes = (card.type for card in cards)

    $target.removeClass('unknown')
    $target.removeClass(allTypes.join(' '))

    $target.addClass(cardType)
    $target.toggleClass('identified', cardType isnt 'unknown')
    $target.trigger('payment.cardType', cardType)

# Public

# Formatting

$.payment.fn.formatCardCVC = ->
  @on('keypress', restrictNumeric)
  @on('keypress', restrictCVC)
  @on('paste', reFormatCVC)
  @on('change', reFormatCVC)
  @on('input', reFormatCVC)
  this

$.payment.fn.formatCardExpiry = ->
  @on('keypress', restrictNumeric)
  @on('keypress', restrictExpiry)
  @on('keypress', formatExpiry)
  @on('keypress', formatForwardSlashAndSpace)
  @on('keypress', formatForwardExpiry)
  @on('keydown',  formatBackExpiry)
  @on('change', reFormatExpiry)
  @on('input', reFormatExpiry)
  this

$.payment.fn.formatCardNumber = ->
  @on('keypress', restrictNumeric)
  @on('keypress', restrictCardNumber)
  @on('keypress', formatCardNumber)
  @on('keydown', formatBackCardNumber)
  @on('keyup', setCardType)
  @on('paste', reFormatCardNumber)
  @on('change', reFormatCardNumber)
  @on('input', reFormatCardNumber)
  @on('input', setCardType)
  this

# Restrictions

$.payment.fn.restrictNumeric = ->
  @on('keypress', restrictNumeric)
  @on('paste', reFormatNumeric)
  @on('change', reFormatNumeric)
  @on('input', reFormatNumeric)
  this

# Validations

$.payment.fn.cardExpiryVal = ->
  $.payment.cardExpiryVal($(this).val())

$.payment.cardExpiryVal = (value) ->
  value = value.replace(/\s/g, '')
  [month, year] = value.split('/', 2)

  # Allow for year shortcut
  if year?.length is 2 and /^\d+$/.test(year)
    prefix = (new Date).getFullYear()
    prefix = prefix.toString()[0..1]
    year   = prefix + year

  month = parseInt(month, 10)
  year  = parseInt(year, 10)

  month: month, year: year

$.payment.validateCardNumber = (num) ->
  num = (num + '').replace(/\s+|-/g, '')
  return false unless /^\d+$/.test(num)

  card = cardFromNumber(num)
  return false unless card

  num.length in card.length and
    (card.luhn is false or luhnCheck(num))

$.payment.validateCardExpiry = (month, year) ->
  # Allow passing an object
  if typeof month is 'object' and 'month' of month
    {month, year} = month

  return false unless month and year

  month = $.trim(month)
  year  = $.trim(year)

  return false unless /^\d+$/.test(month)
  return false unless /^\d+$/.test(year)
  return false unless 1 <= month <= 12

  if year.length == 2
    if year < 70
      year = "20#{year}"
    else
      year = "19#{year}"

  return false unless year.length == 4

  expiry      = new Date(year, month)
  currentTime = new Date

  # Months start from 0 in JavaScript
  expiry.setMonth(expiry.getMonth() - 1)

  # The cc expires at the end of the month,
  # so we need to make the expiry the first day
  # of the month after
  expiry.setMonth(expiry.getMonth() + 1, 1)

  expiry > currentTime

$.payment.validateCardCVC = (cvc, type) ->
  cvc = $.trim(cvc)
  return false unless /^\d+$/.test(cvc)

  card = cardFromType(type)
  if card?
    # Check against a explicit card type
    cvc.length in card.cvcLength
  else
    # Check against all types
    cvc.length >= 3 and cvc.length <= 4

$.payment.cardType = (num) ->
  return null unless num
  cardFromNumber(num)?.type or null

$.payment.formatCardNumber = (num) ->
  num = num.replace(/\D/g, '')
  card = cardFromNumber(num)
  return num unless card

  upperLength = card.length[card.length.length - 1]
  num = num[0...upperLength]

  if card.format.global
    num.match(card.format)?.join(' ')
  else
    groups = card.format.exec(num)
    return unless groups?
    groups.shift()
    groups = $.grep(groups, (n) -> n) # Filter empty groups
    groups.join(' ')

$.payment.formatExpiry = (expiry) ->
  parts = expiry.match(/^\D*(\d{1,2})(\D+)?(\d{1,4})?/)
  return '' unless parts

  mon = parts[1] || ''
  sep = parts[2] || ''
  year = parts[3] || ''

  if year.length > 0
    sep = ' / '

  else if sep is ' /'
    mon = mon.substring(0, 1)
    sep = ''

  else if mon.length == 2 or sep.length > 0
    sep = ' / '

  else if mon.length == 1 and mon not in ['0', '1']
    mon = "0#{mon}"
    sep = ' / '

  return mon + sep + year
