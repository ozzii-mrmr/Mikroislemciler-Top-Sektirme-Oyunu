org 100h

jmp start 

; --- DEGISKENLER ---
top_x dw 40         
top_y dw 12         
eski_top_x dw 40
eski_top_y dw 12

top_yon_x dw 1      
top_yon_y dw 1

plat_x dw 34        ; SIMETRI DÜZELTMESI: Çift sayi ile baslatildi (Duvarlara tam yaslanmasi için)
plat_y dw 23        
plat_genislik dw 12 

eski_plat_x dw 34   
eski_plat_genislik dw 12 

skor dw 0
bekleme_sure dw 1000h 

mesaj_oyun_bitti db '--- GAME OVER ---'
mesaj_secim      db 'R: Yeniden Basla | Q: Cikis'

start:
    ; Video modu (80x25 Metin - 03h)
    mov ax, 0003h
    int 10h

    ; Imleci gizle
    mov ah, 01h
    mov cx, 2607h
    int 10h

game_loop:
    ; 1. ESKI KONUMLARI VE DURUMLARI KAYDET
    mov ax, top_x
    mov eski_top_x, ax
    mov ax, top_y
    mov eski_top_y, ax
    
    mov ax, plat_x
    mov eski_plat_x, ax
    mov ax, plat_genislik
    mov eski_plat_genislik, ax  

    ; 2. KLAVYE KONTROLU
    call check_keyboard

    ; 3. TOPU HAREKET ETTIR
    mov ax, top_x
    add ax, top_yon_x
    mov top_x, ax
    
    mov ax, top_y
    add ax, top_yon_y
    mov top_y, ax

    ; 4. KENAR KONTROLLERI
    cmp top_x, 79
    jge ters_x
    cmp top_x, 0
    jle ters_x
    jmp check_y         

ters_x:
    neg top_yon_x       

check_y:
    cmp top_y, 0
    jle ters_y
    cmp top_y, 24
    jge oyun_bitti      
    jmp platform_kontrol

ters_y:
    neg top_yon_y       

platform_kontrol:
    ; 5. PLATFORM ÇARPISMA KONTROLÜ
    mov ax, top_y
    cmp ax, plat_y      
    jl gorsel_guncelleme       
    
    mov ax, top_x
    cmp ax, plat_x      
    jl gorsel_guncelleme       
    
    mov bx, plat_x
    add bx, plat_genislik
    cmp ax, bx          
    jge gorsel_guncelleme      
    
    ; --- ÇARPISMA GERÇEKLESTI! ---
    neg top_yon_y       
    mov ax, plat_y      
    dec ax              
    mov top_y, ax       

    ; --- HIZLANMA VE KÜÇÜLME MANTIGI ---
    inc skor            
    cmp bekleme_sure, 0400h  
    jle kuculme_kontrol      
    sub bekleme_sure, 0400h  

kuculme_kontrol:
    cmp skor, 5              
    jne gorsel_guncelleme
    cmp plat_genislik, 6     
    jle gorsel_guncelleme
    sub plat_genislik, 6     

    ; --- GÖRSEL GÜNCELLEME ---
gorsel_guncelleme:
    call erase_elements
    call draw_elements  

    ; --- GECIKME (BIOS TIMER) ---
    mov ah, 86h
    mov cx, 0000h
    mov dx, bekleme_sure    
    int 15h

    jmp game_loop

; --- OYUN BITIS VE MENÜ EKRANI ---
oyun_bitti:
    mov ax, 0B800h
    mov es, ax
    cld

    ; "--- GAME OVER ---" yazdir 
    mov di, 1822            
    lea si, mesaj_oyun_bitti
    mov cx, 17              
yaz_bitti_dongu:
    lodsb                   
    mov ah, 0Ch             ; Acik Kirmizi
    stosw                   
    loop yaz_bitti_dongu

    ; "R: Yeniden Basla | Q: Cikis" yazdir 
    mov di, 2132            
    lea si, mesaj_secim
    mov cx, 27              
yaz_secim_dongu:
    lodsb                   
    mov ah, 0Fh             ; Beyaz
    stosw                   
    loop yaz_secim_dongu

secim_bekle:
    mov ah, 00h
    int 16h

    cmp al, 'q'
    je cikis_yap
    cmp al, 'Q'
    je cikis_yap

    cmp al, 'r'
    je oyunu_sifirla
    cmp al, 'R'
    je oyunu_sifirla

    jmp secim_bekle

oyunu_sifirla:
    mov top_x, 40
    mov top_y, 12
    mov eski_top_x, 40
    mov eski_top_y, 12
    
    mov top_yon_x, 1
    mov top_yon_y, 1
    
    mov plat_x, 34        ; SIMETRI DÜZELTMESI (Resetlenirken de 34 olmali)
    mov plat_genislik, 12
    mov eski_plat_x, 34
    mov eski_plat_genislik, 12
    
    mov skor, 0
    mov bekleme_sure, 1000h
    
    jmp start

cikis_yap:
    mov ax, 0003h
    int 10h
    ret 

; --- ALT PROGRAMLAR ---

check_keyboard proc
    mov ah, 01h     
    int 16h
    jz no_key_out       
    
    mov ah, 00h     
    int 16h
    
    cmp ah, 4Bh     
    je move_left
    cmp ah, 4Dh     
    je move_right
no_key_out:
    ret

move_left:
    cmp plat_x, 1  
    jl no_key_out       ; SIMETRI DÜZELTMESI: 0'a kadar gitmesine izin ver
    sub plat_x, 2   
    ret
move_right:
    mov ax, 80          ; SIMETRI DÜZELTMESI: 80 üzerinden hesapla (Sag duvara tam yaslanmasi için)        
    sub ax, plat_genislik       
    cmp plat_x, ax  
    jge no_key_out
    add plat_x, 2   
    ret
check_keyboard endp

draw_elements proc
    mov ax, 0B800h
    mov es, ax
    cld

    ; Top
    mov ax, top_y
    mov bx, 80
    mul bx          
    add ax, top_x   
    shl ax, 1       
    mov di, ax      
    mov word ptr es:[di], 0F4Fh 

    ; Platform
    mov ax, plat_y
    mov bx, 80
    mul bx
    add ax, plat_x
    shl ax, 1
    mov di, ax      
    mov cx, plat_genislik 
    mov ax, 0BDBh               
    rep stosw       

    ; Skor Tabelasi
    mov ax, skor    
    aam             
    
    add ah, 30h     
    add al, 30h
    
    mov di, 0       
    mov word ptr es:[di], 0F53h   
    mov word ptr es:[di+2], 0F4Bh 
    mov word ptr es:[di+4], 0F4Fh 
    mov word ptr es:[di+6], 0F52h 
    mov word ptr es:[di+8], 0F3Ah 
    
    mov bh, 0Fh     
    mov bl, ah      
    mov word ptr es:[di+12], bx   
    
    mov bl, al      
    mov word ptr es:[di+14], bx   
    
    ret
draw_elements endp

erase_elements proc
    mov ax, 0B800h
    mov es, ax
    cld

    ; Eski Topu Sil
    mov ax, eski_top_y
    mov bx, 80
    mul bx
    add ax, eski_top_x
    shl ax, 1
    mov di, ax
    mov word ptr es:[di], 0720h 

    ; Eski Platformu Sil
    mov ax, plat_y
    mov bx, 80
    mul bx
    add ax, eski_plat_x
    shl ax, 1
    mov di, ax      
    mov cx, eski_plat_genislik  
    mov ax, 0720h         
    rep stosw       
    
    ret
erase_elements endp