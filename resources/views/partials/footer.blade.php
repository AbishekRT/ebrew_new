<footer class="bg-[#2d0d1c] text-white px-6 pt-10 pb-4 mt-auto">
  <div class="max-w-7xl mx-auto flex flex-col md:flex-row justify-between items-start text-sm">
    <div class="mb-6 md:mb-0">
      <p class="text-white">Contact us at <a href="mailto:support@ebrew.com" class="underline">support@ebrew.com</a></p>
    </div>
    <div class="text-right space-y-2">
      <p class="font-semibold text-white">Our mission</p>
      <p class="text-gray-300 leading-relaxed max-w-xs">
        Delivering exceptional coffee through quality beans, thoughtful design and a deep commitment to sustainability
      </p>
      <div class="flex justify-end space-x-4 text-orange-500 text-xl">
        <a href="#" title="Instagram" class="hover:text-white"><i class="fab fa-instagram"></i></a>
        <a href="#" title="Facebook" class="hover:text-white"><i class="fab fa-facebook-f"></i></a>
        <a href="#" title="LinkedIn" class="hover:text-white"><i class="fab fa-linkedin-in"></i></a>
        <a href="#" title="Skype" class="hover:text-white"><i class="fab fa-skype"></i></a>
      </div>
    </div>
  </div>
  <div class="mt-8 text-center text-gray-300 text-sm">
    &copy; {{ date('Y') }} eBrew Inc. All Rights Reserved
    @auth
      @if(auth()->user()->Role === 'admin')
        <div class="mt-2">
          <a href="{{ route('admin.dashboard') }}" 
             class="text-xs text-gray-400 hover:text-gray-200 underline transition">
            Admin Panel
          </a>
        </div>
      @endif
    @endauth
  </div>
</footer>
