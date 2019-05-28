def build_confirmation_menu(question, defaultResponse=None):

  response = None
  default_prompt = "(y/n)"
  if defaultResponse:
    default_prompt = "(Y/n)"
  elif defaultResponse != None:
    default_prompt = "(y/N)"

  print(question, default_prompt, ":", end=" ")
  while response == None:
    raw_response = input()
    if not raw_response and defaultResponse != None:
      response = defaultResponse
    # elif not raw_response:
    #   print('Invalid selection! Please try again.')
    elif raw_response in ['Y','y']:
      response = True
    elif raw_response in ['N','n']:
      response = False
    else:
      print('Invalid selection! Please try again.')

  return response