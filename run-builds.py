#!/usr/bin/env python
import os
import time

status_done_text = ""
with open("/scratch/git/coin_replace_done.html", "r") as f:
	status_done_text = f.read()

status_building_text = ""
with open("/scratch/git/coin_replace_building.html", "r") as f:
	status_building_text = f.read()

status_waiting_text = ""
with open("/scratch/git/coin_replace_waiting.html", "r") as f:
	status_waiting_text = f.read()

while True:
	status_list_first = ""
	status_list_second = ""
	status_list_third = ""
	for magic in os.listdir('/scratch/output/'):
		try:
			btcfile = open('/scratch/output/' + magic + '/btc_info.txt')
			cost = float(btcfile.readline().rstrip())
			recv_address = btcfile.readline().rstrip()
			current_val = float(btcfile.readline().rstrip())
			infofile = open('/scratch/output/' + magic + '/info.txt')
			infofile.readline()
			name = infofile.readline().rstrip()
			abrev = infofile.readline().rstrip()
			proofOW = infofile.readline().rstrip()
			port = infofile.readline().rstrip()
			customload = 1 if infofile.readline().rstrip() == "true" else 0
			source = 1 if infofile.readline().rstrip() == "true" else 0
			blockRate = infofile.readline().rstrip()
			initValue = infofile.readline().rstrip()
			halfRate = infofile.readline().rstrip()
			hidden = 1 if infofile.readline().rstrip() == "true" else 0

			if (current_val < cost):
				print(magic + ' hasnt paid yet (' + str(current_val) + '/' + str(cost) + ')')
				if hidden is 0:
					local_status = status_waiting_text
					local_status = local_status.replace("$NAME", name)
					local_status = local_status.replace("$VALUE", str(cost - current_val))
					local_status = local_status.replace("$ADDRESS", recv_address)
					status_list_third += local_status
				continue
			if os.path.isfile('/scratch/output/' + magic + '/done'):
				if hidden is 0:
					local_status = status_done_text
					local_status = local_status.replace("$NAME", name)
					local_status = local_status.replace("$URL", "http://coingen.bluematt.me/build/" + magic + ".zip")
					status_list_first += local_status
				continue

			print('Building ' + name)
			retVal = os.system('/scratch/git/makecoin.sh ' + name + ' ' + proofOW + ' ' + str(source) + ' ' + port + ' /scratch/output/' + magic + '/logo.png ' + abrev + ' ' + magic + ' ' + str(customload) + ' ' + blockRate + ' ' + initValue + ' ' + halfRate)
			if retVal == 0:
				os.system('mv /scratch/output/' + magic + '/' + name + '.zip /var/www/build/' + magic + '.zip')
				os.system('touch /scratch/output/' + magic + '/done')
		except:
			print('Got an exception')

	with open("/scratch/git/status.html", 'r') as status_file:
		status_contents = status_file.read()
		status_list = status_list_first + status_list_second + status_list_third
		status_contents = status_contents.replace("REPLACE", status_list)
		output = open("/var/www/status.html", "w")
		output.write(status_contents)

	time.sleep(10)
