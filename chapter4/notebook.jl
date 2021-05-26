### A Pluto.jl notebook ###
# v0.14.5

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 4ef50e80-bd23-11eb-3b49-21a3850f95c5
begin
	import Pkg
	Pkg.activate(mktempdir())
	Pkg.add([
		Pkg.PackageSpec(name="ImageIO", version="0.5"),
		Pkg.PackageSpec(name="ImageShow", version="0.2"),
		Pkg.PackageSpec(name="FileIO", version="1.6"),
		Pkg.PackageSpec(name="PNGFiles", version="0.3.6"),
		Pkg.PackageSpec(name="Colors", version="0.12"),
		Pkg.PackageSpec(name="ColorVectorSpace", version="0.8"),
		
		Pkg.PackageSpec(name="PlutoUI", version="0.7"), 
		Pkg.PackageSpec(name="Unitful", version="1.6"), 
		Pkg.PackageSpec(name="ImageFiltering", version="0.6"),
		Pkg.PackageSpec(name="OffsetArrays", version="1.6"),
		Pkg.PackageSpec(name="Plots", version="1.10")
	])

	using PlutoUI 
	using Colors, ColorVectorSpace, ImageShow, FileIO
	using Unitful 
	using ImageFiltering
	using OffsetArrays
	using Plots
end

# ╔═╡ b929a7e7-7abf-4fed-90c4-9ece57ebd87b
md"
## 4 การประมวลผลภาพ

ตามที่ได้อธิบายในบทที่ 1 ข้อมูลของภาพถูกจัดเก็บในรูปแบบที่ไม่แตกต่างจากเมทริกซ์ โดยค่าของสมาชิกในเมทริกซ์ก็คือค่าของสีในแต่ละพิกเซลนั่นเอง ดังนั้นการประมวลผลภาพ (image processing) ก็คือการดำเนินการทางคณิตศาสตร์กับเมทริกซ์ เช่นเมื่อคูณทั้งเมทริกซ์ด้วยค่าคงที่คือการปรับค่าของแสง ในบทที่ 1 ได้สาธิตการดำเนินการขั้นพื้นฐาน เช่นการตัดเฉพาะส่วนที่ต้องการ การลดขนาดภาพ ในบทนี้จะเป็นการศึกษาการประมวลผลภาพที่ซับซ้อนมากขึ้น เช่นการทำให้ชัดขึ้น (sharpen) หรือชัดน้อยลง (blur) การตรวจจับขอบ (edge detection) และการแปลงภาพประเภทต่างๆ ในการศึกษาเกี่ยวกับพีชคณิตเชิงเส้นมักพบว่าการดำเนินการหลายประเภทถูกแสดงได้อย่างชัดเจนมากกว่าเมื่อใช้ภาพเป็นอินพุตและเอาต์พุต 

สร้างสมุดบันทึกพลูโตใหม่สำหรับการศึกษาในบทนี้ และนำเข้าแพคเกจที่ใช้งาน 

"

# ╔═╡ 8ddbc926-f18e-4bc8-b970-49e1d04db2e3
md"""
รูปที่ใช้ในบทนี้คือแมวชื่อ chaba หมอบอยู่บนเสื้อเชิ้ตที่มีข้อความเป็นตัวอักษรภาษาอังกฤษ เมื่อนำไฟล์ chaba.png ไว้ในไดเรคทอรีเดียวกับสมุดบันทึก สามารถใช้ฟังก์ชัน load() เพื่อแสดงภาพดังในรูปที่ 4.1 (หรือดาวน์โหลดจาก Google drive ของผู้เขียน)
"""

# ╔═╡ 2797aa9d-7bb2-4752-bde4-a6dfa04bacd1
#chaba = load("chaba.png")
chaba = load(download("https://drive.google.com/uc?id=1XXFOln3HSEawW_I7-N3uAJfI2fu_Et6Y"))

# ╔═╡ ad50e1c3-c735-4494-8c8f-49b336b30677
chaba_size = size(chaba)

# ╔═╡ f0fc8fec-6875-41b3-aadd-c4e3a6b3e16b
md"""
### 4.1 การปรับค่าแสง

เนื่องจากค่าของสมาชิกในเมทริกซ์ที่เป็นข้อมูลภาพก็คือความเข้มแสงของแต่ละพิกเซล ดังนั้นการประมวลภาพที่ง่ายที่สุดคือการปรับความสว่างของแต่ละจุดพิกเซลโดยการคูณด้วยค่าคงที่ สามารถใช้สไลเดอร์ในการปรับได้ดังนี้ 
"""

# ╔═╡ 704ee77f-0567-48ac-b056-2b1453d73ca9
@bind brightness Slider(0:0.1:5, show_value=true, default=1)

# ╔═╡ 48d7c3fd-d5b0-4b64-816c-1e10df45fcc3


# ╔═╡ e1e3f907-7a64-45f9-b07c-aa6138331e45
chaba_br = brightness*chaba

# ╔═╡ 0cf0730b-695d-4e42-becf-92589c776e46
md"""
### 4.2 การตัดส่วนภาพ

ในบทที่ 1 ได้สาธิตการตัดภาพเฉพาะส่วนที่ต้องการ เช่นหากต้องการตัดเฉพาะส่วนที่เป็นแมว จะได้ดังรูปที่ 4.3 

"""

# ╔═╡ 3ed0f90c-0bac-435d-b34d-520ea54912ba
chaba_crop = chaba[50:300, 100:550]

# ╔═╡ a34b86b9-1444-456d-ab2b-1857eddb2326


# ╔═╡ 6aa12ae2-343c-41a6-b181-740d574cc9ac


# ╔═╡ 84ab49b0-ffcd-4c28-9fc9-a4f2efe54d1f
md"""
### 4.3 การกำหนดทิศทาง

การกำหนดทิศทาง (orientation) ในความหมายของช่างภาพคือภาพบุคคล (portrait) หรือภาพทิวทัศน์ (landscape) ในที่นี้รวมถึงถึงการเปลี่ยนรูปแบบการแสดงภาพในลักษณะเชิงตั้งฉากทั้งหมด เช่นเปลี่ยนจากแนวตั้งเป็นแนวนอน ซึ่งก็คือการหมุน 90 องศาในทิศทางตามเข็มหรือทวนเข็ม หรือกลับหัวภาพ (หมุน 180 องศา) 

แนวคิดในเบื้องต้นคือการดำเนินการสลับเปลี่ยน (transpose) กับเมทริกซ์ภาพโดยคำสั่ง transpose(chaba_crop) จะสามารถเปลี่ยนรูปแบบจากแนวนอนเป็นแนวตั้ง แต่จากเอาต์พุตจะพบว่านอกจากป็นการหมุนทวนเข็มแล้ว ภาพยังมีลักษณะสะท้อน (mirror image) เหมือนมองในกระจกเงา ดังนั้นหากไม่ต้องการให้ภาพกลับด้านต้องใช้คำสั่งดังแสดงในรูปที่ 4.4

แบบฝึกหัด :
เขียนโค้ดจูเลียเพื่อหมุนภาพ chaba_crop ตามเข็มนาฬิกาและกลับหัว โดยแสดงภาพทั้งแบบปกติและภาพกระจกเงา	

"""

# ╔═╡ ad309736-19ea-4748-ba68-181fc801f1a4
# transpose(chaba_crop)
chaba_crop'

# ╔═╡ 0c952b62-852a-4307-b875-875d44e95f09
transpose(chaba_crop)[end:-1:1, :] # รูปที่ 4.4

# ╔═╡ f905e1a2-13a5-45ed-9a80-e14380a90e7c
md"""
### 4.4 การแปลงภาพโดยวิธีสังวัตนาการ

การแปลงภาพในหลายรูปแบบ เช่น  การเพิ่มหรือลดความชัด การตรวจหาขอบ สามารถทำได้โดยอาศัยการดำเนินการสังวัตนาการ (convolution) ระหว่างภาพกับเคอร์เนล (kernel) ที่มีขนาดและค่าสมาชิกตามที่กำหนด การเลือกค่าสมาชิกในเคอร์เนลคือส่วนสำคัญที่ทำให้เกิดเอาต์พุตตามต้องการ  

ตัวกรองที่ใช้สำหรับการประมวลผลภาพอาจมีความแตกต่างจากตัวอย่างด้านบน แต่สามารถให้เอาต์พุตได้ตามความต้องการของผู้ใช้ การสังวัตนาการโดยจูเลียสามารถทำได้โดยใช้คำสั่งเพื่อดำเนินการทางคณิตศาสตร์โดยตรง  หรือว่าใช้แพคเกจ ImageFiltering ที่ได้นำเข้าในเซลแรกของสมุดบันทึก เพื่อความสะดวกเราจะใช้ฟังก์ชันสนับสนุนจากแพคเกจ

#### 4.4.1 การสร้างเคอร์เนล

เพื่อทดสอบการประมวลผลภาพโดยวิธีสังวัตนาการ จะเขียนโค้ดบนสมุดบันทึกเดิมโดยใช้รูปที่ 4.1 เป็นต้นแบบ เริ่มต้นโดยสร้างฟังก์ชัน kernelize() เพื่อกำหนดตัวชี้ของสมาชิกตำแหน่งกลางให้มีค่าเท่ากับ [0,0]



"""

# ╔═╡ 36b97ea9-c502-4120-9d21-9cc5cd9e81d0
kernelize(M) = OffsetArray( M, -1:1, -1:1)	     

# ╔═╡ a4f2f60c-1d1c-4ef3-92eb-857b54ee5f28
begin
	A = [1 2 3;4 5 6;7 8 9]
	B = kernelize(A)
	B_indixes = [c.I for c ∈ CartesianIndices(B)]
end

# ╔═╡ 8029e596-f6c5-4549-a96b-8a38bfb8a94a
md"""
เพื่อความสะดวกในการทดสอบ จะสร้างกล่องเมนูสำหรับผู้ใช้เพื่อสามารถเลือกชนิดของตัวกรองได้โดยง่าย โดยมีเคอร์เนลเป็นตัวเลือกคือ เอกลักษณ์ (ไม่มีการเปลี่ยนแปลง) ตรวจหาขอบ เพิ่มความชัด ลดความชัด ตรวจสอบความชันในแนวตั้งและแนวนอน ดังแสดงในเซลนี้


"""

# ╔═╡ a814e4bc-9bc9-4e8e-be0c-51104bdeb66b
begin
	identity = [0 0 0 ; 0 1 0 ; 0 0 0]
	edge_detect = [0 -1 0; -1 4 -1; 0 -1 0] 
	sharpen = identity .+ edge_detect  # Superposition!
	box_blur = [1 1 1;1 1 1;1 1 1]/9
	∇x = [-1 0 1;-1 0 1;-1 0 1]/2 # centered deriv in x
	∇y = ∇x'
	
	kernels = [identity, edge_detect, sharpen, box_blur, ∇x, ∇y]
	kernel_keys =["identity", "edge_detect", "sharpen", "box_blur", "∇x", "∇y"]
	selections = kernel_keys .=> kernel_keys
	kernel_matrix = Dict(kernel_keys .=> kernels)
	md"$(@bind kernel_name Select(selections))"
end

# ╔═╡ 307ee9b8-04e7-417f-99ec-ffb0ff3a9926
kernel_matrix[kernel_name]

# ╔═╡ 591fdcf9-9671-4f41-ab91-e5445c77b140
md"""
โดยกล่องตัวเลือกที่เป็นเอาต์พุตของเซลสามารถดึงลงเพื่อเลือกชนิดของเคอร์เนลที่ต้องการได้ โดยแสดงเคอร์เนลที่เลือกในเซลด้านล่าง การสร้างส่วนติดต่อผู้ใช้งานในลักษณะนี้มีประโยชน์เมื่อเราต้องการเลือกค่าหนึ่งจากกลุ่มของตัวเลือกทั้งหมด ผู้อ่านสามารถดัดแปลงโค้ดไปใช้ในงานที่ต้องการได้โดยไม่ยาก

โค้ดสำหรับประมวลผลภาพวิธีสังวัตนาการ โดยแพคเกจ ImageFiltering เขียนได้ดังนี้

"""

# ╔═╡ b4500520-f660-465b-8a6c-d46b838cf122


# ╔═╡ 58769872-5ae7-4ed1-9614-691f496a28c0
imfilter( chaba, kernelize(kernel_matrix[kernel_name]))

# ╔═╡ 7861410b-a170-4604-a49a-9232c4a8d0d8
Gray.(1.5 .* abs.(imfilter( chaba, kernelize(kernel_matrix[kernel_name]))))

# ╔═╡ 1d0689d3-1ac0-4df5-9ac4-a921a5ed6038
md"""
#### 4.4.2 เคอร์เนลขั้นสูง

ในความหมายของเคอร์เนลขั้นสูงในหัวข้อย่อยนี้คือ เคอร์เนลที่มีขนาดใหญ่กว่า 3 x 3 หรือใช้ฟังก์ชันทางคณิตศาสตร์เพื่อสร้างสมาชิก โดยจะยกตัวอย่างเคอร์เนลแบบเกาส์เซียนที่สามารถใช้ในการลดความชัดของภาพ โดยพิจารณาหลักความจริงของภาพโดยทั่วไปว่ามีองค์ประกอบสำคัญอยู่ที่บริเวณส่วนกลางภาพมากกว่าส่วนขอบ ดังนั้นอาจเลือกให้น้ำหนักมากกับสมาชิกบริเวณส่วนกลางเคอร์เนลแทนการใช้ค่าเฉลี่ยของสมาชิกทั้งหมด ในทางคณิตศาสตร์สามารถทำได้โดยฟังก์ชันเกาส์เซียนในสองมิติ
``
$
h(x,y) = e^{-\frac{x^2+y^2}{2}}, \, -a \le x \le a, \, -b \le y \le b
$
``
สมมุติว่าต้องการสร้างเคอร์เนลแบบเกาส์เซียนขนาด 5 x 5 สามารถสร้างได้โดยโค้ดดังนี้

"""

# ╔═╡ 6ff3d316-5947-43fa-b894-4f0d77914db7
begin
	H = [exp( -(i^2+j^2)/2) for i=-2:2, j=-2:2]
	round.(H ./ sum(H), digits=3)
end

# ╔═╡ b6b3e33a-8fcf-4a82-861c-c5b74d696bee
md"""
หากใช้แพคเกจ ImageFiltering ใช้ฟังก์ชัน Kernel.gaussian() ซึ่งจะให้ผลลัพธ์เหมือนกัน
"""

# ╔═╡ 8151dc5d-3a3a-44c4-be03-22e4aa8155d7
round.(Kernel.gaussian(1), digits=3)

# ╔═╡ 8737bcab-ede9-4583-abb7-810c327b64ca
md"""
ค่าในอาร์กิวเมนต์ของ Kernel.gaussian()  คือค่าเบี่ยงเบนมาตรฐาน เมื่อสังเกตค่าสมาชิกของเคอร์เนลแบบเกาส์เซียนจะพบว่าค่าน้ำหนักของสมาชิกในตำแหน่งกลางจะมีค่าสูงสุด และค่าจะลดลงในลักษณะคล้ายรูประฆังคว่ำ การแสดงมโนภาพนี้ทำได้โดยคำสั่งการพล็อตของจูเลีย สร้างสไลเดอร์สำหรับตัวแปร hparam และพล็อดเคอร์เนลโดยคำสั่ง
"""

# ╔═╡ 4b4c9139-126d-4771-8c0c-320974d1d077
@bind hparam Slider(0:9, show_value=true, default=1)

# ╔═╡ d32111c5-248b-4c04-b79c-862705cbdd6c
kernel = Kernel.gaussian(hparam)

# ╔═╡ 5c78b540-a8df-493f-85be-45ea6c556bff
plotly()

# ╔═╡ 488f2020-0a69-47d8-9b60-ee67a1cc248b
surface([kernel;]) #รูปที่ 4.7

# ╔═╡ 69ea91f7-f2e7-4056-aa78-1554e72126ea
md"""
สังเกตว่าเคอร์เนลจะมีขนาดใหญ่ขึ้นตามค่าของตัวแปร hparam ซึ่งก็คือค่าเบี่ยงเบนมาตรฐานของฟังก์ชันเกาส์เซียน 2 มิติ
 
หากต้องการทดสอบเคอร์เนลแบบเกาส์เซียนที่สร้างขึ้นกับรูปภาพ chaba ก็สามารถทำได้โดยดัดแปลงโค้ดเดิม โดยขั้นแรกสังเกตว่าขนาดของเคอร์เนลที่สร้างในรูปที่ 4.7 จะเปลี่ยนแปลงตามค่าเบี่ยงเบนมาตรฐานที่ปรับโดยสไลเดอร์ ขณะที่โค้ดเดิมที่สร้างเอาต์พุตรูปที่ 4.6 จะทำงานได้เฉพาะเคอร์เนลขนาด 3 x 3 ดังนั้นเราต้องหาขนาดเคอร์เนลจากตัวแปร kernel ที่ถูกสร้างขึ้นตามขั้นตอนในรูปที่ 4.7 และสร้างตัวแปรเพื่อกำหนดค่าขอบเขตของตัวชี้เพื่อให้สมาชิกตำแหน่งกลางคือ [0,0] ตัวอย่างเช่นเมื่อปรับค่า hparam = 5 ขนาดของเคอร์เนลคือ 21 x 21 ใช้โค้ดในเซลนี้เพื่อคำนวณค่าขอบเขตได้เท่ากับ 10 และเก็บในตัวแปร index_limit 
"""

# ╔═╡ e8f96b9f-ed21-4266-be85-cc0e3f5b57ba
begin
	kernel_size = size(kernel)[1]
	index_limit = Int(floor(kernel_size/2))
end
	

# ╔═╡ 8b7528d3-10b9-4ad4-aaee-0b4da0152b8d
md"""
เขียนฟังก์ชันออฟเซ็ตตัวชี้ใหม่ให้ยืดหยุ่นรองรับขนาดของเคอร์เนลที่ไม่คงที่
"""

# ╔═╡ b577c784-82b3-47bb-8354-cdbcbf04f42c
kernelize_h(M) = OffsetArray( M, -index_limit:index_limit, -index_limit:index_limit)	

# ╔═╡ f289b6c4-44e0-4b49-ac27-40e09e5e6c77
md"""
ใช้ฟังก์ชัน imfilter()  เพียงเปลี่ยนฟังก์ชัน kernelize() เดิมเป็น kernelize_h() ผลที่ได้เป็นดังรูปที่ 4.8
"""

# ╔═╡ f64b8e66-4b62-4b35-932e-fb9a9947aa15

imfilter( chaba, kernelize_h(kernel))

# ╔═╡ 77fc494c-99d0-4948-b730-b7b842dd6adb


# ╔═╡ 6602bbe2-1061-47bb-97bb-1ee3f12f9fed


# ╔═╡ eb8b446d-7c0a-4af6-8d09-b154e6c394d0


# ╔═╡ Cell order:
# ╟─b929a7e7-7abf-4fed-90c4-9ece57ebd87b
# ╠═4ef50e80-bd23-11eb-3b49-21a3850f95c5
# ╟─8ddbc926-f18e-4bc8-b970-49e1d04db2e3
# ╠═2797aa9d-7bb2-4752-bde4-a6dfa04bacd1
# ╠═ad50e1c3-c735-4494-8c8f-49b336b30677
# ╟─f0fc8fec-6875-41b3-aadd-c4e3a6b3e16b
# ╠═704ee77f-0567-48ac-b056-2b1453d73ca9
# ╠═48d7c3fd-d5b0-4b64-816c-1e10df45fcc3
# ╠═e1e3f907-7a64-45f9-b07c-aa6138331e45
# ╟─0cf0730b-695d-4e42-becf-92589c776e46
# ╠═3ed0f90c-0bac-435d-b34d-520ea54912ba
# ╠═a34b86b9-1444-456d-ab2b-1857eddb2326
# ╠═6aa12ae2-343c-41a6-b181-740d574cc9ac
# ╟─84ab49b0-ffcd-4c28-9fc9-a4f2efe54d1f
# ╠═ad309736-19ea-4748-ba68-181fc801f1a4
# ╠═0c952b62-852a-4307-b875-875d44e95f09
# ╟─f905e1a2-13a5-45ed-9a80-e14380a90e7c
# ╠═36b97ea9-c502-4120-9d21-9cc5cd9e81d0
# ╠═a4f2f60c-1d1c-4ef3-92eb-857b54ee5f28
# ╟─8029e596-f6c5-4549-a96b-8a38bfb8a94a
# ╠═a814e4bc-9bc9-4e8e-be0c-51104bdeb66b
# ╠═307ee9b8-04e7-417f-99ec-ffb0ff3a9926
# ╟─591fdcf9-9671-4f41-ab91-e5445c77b140
# ╠═b4500520-f660-465b-8a6c-d46b838cf122
# ╠═58769872-5ae7-4ed1-9614-691f496a28c0
# ╠═7861410b-a170-4604-a49a-9232c4a8d0d8
# ╟─1d0689d3-1ac0-4df5-9ac4-a921a5ed6038
# ╠═6ff3d316-5947-43fa-b894-4f0d77914db7
# ╟─b6b3e33a-8fcf-4a82-861c-c5b74d696bee
# ╠═8151dc5d-3a3a-44c4-be03-22e4aa8155d7
# ╠═8737bcab-ede9-4583-abb7-810c327b64ca
# ╠═4b4c9139-126d-4771-8c0c-320974d1d077
# ╠═d32111c5-248b-4c04-b79c-862705cbdd6c
# ╠═5c78b540-a8df-493f-85be-45ea6c556bff
# ╠═488f2020-0a69-47d8-9b60-ee67a1cc248b
# ╟─69ea91f7-f2e7-4056-aa78-1554e72126ea
# ╠═e8f96b9f-ed21-4266-be85-cc0e3f5b57ba
# ╟─8b7528d3-10b9-4ad4-aaee-0b4da0152b8d
# ╠═b577c784-82b3-47bb-8354-cdbcbf04f42c
# ╟─f289b6c4-44e0-4b49-ac27-40e09e5e6c77
# ╠═f64b8e66-4b62-4b35-932e-fb9a9947aa15
# ╠═77fc494c-99d0-4948-b730-b7b842dd6adb
# ╠═6602bbe2-1061-47bb-97bb-1ee3f12f9fed
# ╠═eb8b446d-7c0a-4af6-8d09-b154e6c394d0
